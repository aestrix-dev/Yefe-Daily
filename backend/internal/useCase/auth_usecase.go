package usecase

import (
	"context"
	"encoding/hex"
	"fmt"
	"strings"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/logger"
	"yefe_app/v1/pkg/services/fire_base"
	"yefe_app/v1/pkg/types"
	"yefe_app/v1/pkg/utils"

	"github.com/golang-jwt/jwt"
	"github.com/google/uuid"
)

type authUseCase struct {
	userRepo     domain.UserRepository
	sessionRepo  domain.SessionRepository
	secEventRepo domain.SecurityEventRepository
	//emailService    EmailService
	passwordChecker types.PasswordChecker
	jwtSecret       string
	fmcService      *fire_base.FCMNotificationService
}

var (
	now = time.Now()

	timeLayout = "15:04"
)

func NewAuthUseCase(
	userRepo domain.UserRepository,
	sessionRepo domain.SessionRepository,
	secEventRepo domain.SecurityEventRepository,
	jwtSecret string,
	fmcService *fire_base.FCMNotificationService,

) domain.AuthUseCase {
	return &authUseCase{
		userRepo:     userRepo,
		sessionRepo:  sessionRepo,
		secEventRepo: secEventRepo,
		//	emailService:    emailService,
		passwordChecker: utils.NewBasicPasswordChecker(),
		jwtSecret:       jwtSecret,
		fmcService:      fmcService,
	}
}

func (a *authUseCase) Register(ctx context.Context, req dto.RegisterRequest) (*domain.User, error) {

	// Validate password strength
	if !a.passwordChecker.IsStrong(req.Password) {
		return nil, domain.ErrWeakPassword
	}

	// Check if email exists
	if _, err := a.userRepo.GetByEmail(ctx, req.Email); err == nil {
		return nil, domain.ErrEmailAlreadyExists
	}

	// Generate salt and hash password
	salt := utils.GenerateSalt(utils.DefaultPasswordConfig.SaltLength)
	passwordHash := utils.HashPassword(req.Password, salt, utils.DefaultPasswordConfig)

	user := &domain.User{
		ID:           utils.GenerateID(),
		Email:        strings.ToLower(strings.TrimSpace(req.Email)),
		Name:         strings.TrimSpace(req.Name),
		PasswordHash: passwordHash,
		Salt:         salt,
		IsActive:     true,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	user.DowngradeToFree()

	prefs := req.Prefs

	reminders := types.ReminderRequest{
		MorningReminder: types.ReminderStr(prefs.Reminders.MorningReminder),
		EveningReminder: types.ReminderStr(prefs.Reminders.EveningReminder),
	}

	userPrefs := &types.NotificationsPref{
		MorningPrompt:     prefs.MorningPrompt,
		EveningReflection: prefs.EveningReflection,
		Challenge:         prefs.Challenge,
		Language:          prefs.Language,
		Reminders:         reminders,
	}

	if err := a.userRepo.Create(ctx, user, *userPrefs); err != nil {
		logger.Log.WithError(err).Error("error creating user")
		return nil, err
	}

	// Send email verification
	//go a.sendEmailVerification(user)

	// Log security event
	a.secEventRepo.LogSecurityEvent(ctx, user.ID, types.EventAccountCreated, req.IPAddress, req.UserAgent, types.JSONMap{
		"message": "User created",
	})

	return user, nil
}

func (a *authUseCase) Login(ctx context.Context, req dto.LoginRequest) (*dto.LoginResponse, error) {

	// Find user by email or username
	var user *domain.User
	var err error

	user, err = a.userRepo.GetByEmail(ctx, req.Email)

	if err != nil {
		return nil, domain.ErrInvalidCredentials
	}

	// Check if account is locked
	if user.AccountLockedUntil != nil && time.Now().Before(*user.AccountLockedUntil) {
		return nil, domain.ErrAccountLocked
	}

	// Check if account is active
	if !user.IsActive {
		logger.Log.WithError(err).Error("Account inactive")
		return nil, domain.ErrAccountInactive
	}

	// Verify password
	if !utils.VerifyPassword(req.Password, user.Salt, user.PasswordHash, utils.DefaultPasswordConfig) {
		user.FailedLoginCount++
		user.LastFailedLogin = &time.Time{}
		*user.LastFailedLogin = time.Now()

		// Lock account after 5 failed attempts TODO this does not make any sense
		if user.FailedLoginCount >= 5 {
			lockUntil := time.Now().Add(time.Hour * 1)
			user.AccountLockedUntil = &lockUntil
			a.secEventRepo.LogSecurityEvent(ctx, user.ID, types.EventAccountLocked, req.IPAddress, req.UserAgent, nil)
		}

		a.secEventRepo.LogSecurityEvent(ctx, user.ID, types.EventLoginFailed, req.IPAddress, req.UserAgent, nil)
		logger.Log.WithError(err).Error("Invalid password or email")
		return nil, domain.ErrInvalidCredentials
	}

	// Reset failed login count on successful login
	user.FailedLoginCount = 0
	user.LastFailedLogin = nil
	user.AccountLockedUntil = nil
	user.LastLoginAt = &time.Time{}
	*user.LastLoginAt = time.Now()
	user.LastLoginIP = req.IPAddress
	//a.userRepo.Update(ctx, user)

	// Create session
	session := &domain.Session{
		ID:           uuid.New().String(),
		UserID:       user.ID,
		Token:        utils.GenerateSecureToken(),
		RefreshToken: utils.GenerateSecureToken(),
		ExpiresAt:    time.Now().Add(time.Hour * 24), // 24 hours
		IPAddress:    req.IPAddress,
		UserAgent:    req.UserAgent,
		IsActive:     true,
		CreatedAt:    time.Now(),
	}

	if err := a.sessionRepo.Create(ctx, session); err != nil {
		return nil, err
	}

	// Generate JWT
	accessToken, err := a.generateJWT(user.ID, session.ID)
	if err != nil {
		return nil, err
	}

	a.secEventRepo.LogSecurityEvent(ctx, user.ID, types.EventLogin, req.IPAddress, req.UserAgent, nil)

	err = a.userRepo.UpdateLastLogin(ctx, user.ID)
	if err != nil {
		logger.Log.WithError(err).Error("Could not update last login")
	}
	return &dto.LoginResponse{
		AccessToken:  accessToken,
		RefreshToken: session.RefreshToken,
		ExpiresIn:    int64(time.Hour * 24 / time.Second),
	}, nil
}

func (a *authUseCase) Logout(ctx context.Context, req dto.LogoutRequest) error {
	// Get session from repository
	session, err := a.sessionRepo.GetByID(ctx, req.SessionID)
	if err != nil || session == nil {
		a.secEventRepo.LogSecurityEvent(ctx, "", types.EventLoginFailed, req.IPAddress, req.UserAgent,
			map[string]any{"reason": "session_not_found"})
		return domain.ErrSessionNotFound
	}

	// Check if session is already inactive
	if !session.IsActive {
		return domain.ErrSessionAlreadyInactive
	}

	// Check if session has expired
	if time.Now().After(session.ExpiresAt) {
		return domain.ErrAccountInactive
	}

	// Deactivate the session
	session.IsActive = false
	session.LoggedOutAt = time.Now()

	// Update session in repository
	if err := a.sessionRepo.Update(ctx, session); err != nil {
		a.secEventRepo.LogSecurityEvent(ctx, session.UserID, types.EventLogoutFailed, req.IPAddress, req.UserAgent,
			map[string]any{"reason": "database_error"})
		return err
	}

	// Log successful logout
	a.secEventRepo.LogSecurityEvent(ctx, session.UserID, types.EventLogout, req.IPAddress, req.UserAgent, nil)

	return nil
}

func (a *authUseCase) AcceptNotificaions(ctx context.Context, fcmToken string, user *domain.User) error {

	preferences := fire_base.FCMUserPreferences{
		FCMToken:    fcmToken,
		MorningTime: user.Profile.NotificationPreferences.Reminders.MorningReminder.String(),
		EveningTime: user.Profile.NotificationPreferences.Reminders.EveningReminder.String(),
		Timezone:    "America/New_York",
	}
	if err := a.fmcService.UpdateUserPreferences(ctx, user.ID, preferences); err != nil {
		logger.Log.WithError(err).Error("Failed to update user preferences")
	}

	morningTime := strings.Split(preferences.MorningTime, ":")
	evnT, err := fire_base.ConvertTo24Hour(preferences.EveningTime)
	if err != nil {
		return err
	}

	eveningTime := strings.Split(evnT, ":")

	morningHour := morningTime[0]
	morningMinute := morningTime[1]

	eveningHour := eveningTime[0]
	eveningMinute := eveningTime[1]

	morningCron := fmt.Sprintf("0 %s %s * * *", morningMinute, morningHour)
	eveningCron := fmt.Sprintf("0 %s %s * * *", eveningMinute, eveningHour)
	if err := a.fmcService.AddRecurringNotification(
		utils.GenerateID()+utils.GenerateSecureToken(),
		preferences.UserID,
		"Daily Motivation",
		"Here's your daily dose of motivation!",
		morningCron,
		map[string]string{"type": "daily"}); err != nil {
		logger.Log.WithError(err).Error("Failed to add recurring notification")
		return err
	}
	if err := a.fmcService.AddRecurringNotification(
		utils.GenerateID()+utils.GenerateSecureToken(),
		preferences.UserID,
		"Daily Motivation",
		"Here's your daily dose of motivation!",
		eveningCron,
		map[string]string{"type": "daily"},
	); err != nil {
		logger.Log.WithError(err).Error("Failed to add recurring notification")
		return err

	}
	return nil

}

func (a *authUseCase) generateJWT(userID, sessionID string) (string, error) {
	claims := jwt.MapClaims{
		"user_id":    userID,
		"session_id": sessionID,
		"exp":        time.Now().Add(time.Hour * 24).Unix(),
		"iat":        time.Now().Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	secret, err := hex.DecodeString(a.jwtSecret)
	if err != nil {
		return "", fmt.Errorf("invalid JWT secret encoding: %w", err)
	}

	return token.SignedString(secret)
}
