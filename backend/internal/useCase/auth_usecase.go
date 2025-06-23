package usecase

import (
	"context"
	"strings"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
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
}

var defaultPasswordConfig = types.PasswordConfig{
	Memory:      64 * 1024, // MB
	Iterations:  3,
	Parallelism: 2,
	SaltLength:  16,
	KeyLength:   32,
}

func NewAuthUseCase(
	userRepo domain.UserRepository,
	sessionRepo domain.SessionRepository,
	secEventRepo domain.SecurityEventRepository,
	jwtSecret string,
) domain.AuthUseCase {
	return &authUseCase{
		userRepo:     userRepo,
		sessionRepo:  sessionRepo,
		secEventRepo: secEventRepo,
		//	emailService:    emailService,
		passwordChecker: utils.NewBasicPasswordChecker(),
		jwtSecret:       jwtSecret,
	}
}

func (a *authUseCase) Register(ctx context.Context, req dto.RegisterRequest) (*domain.User, error) {

	// Validate password strength
	if !a.passwordChecker.IsStrong(req.Password) {
		return nil, domain.ErrWeakPassword
	}

	// Check if email exists
	if existingUser, _ := a.userRepo.GetByEmail(ctx, req.Email); existingUser != nil {
		return nil, domain.ErrEmailAlreadyExists
	}

	// Check if username exists
	if existingUser, _ := a.userRepo.GetByEmail(ctx, req.Email); existingUser != nil {
		return nil, domain.ErrUsernameAlreadyExists
	}

	// Generate salt and hash password
	salt := utils.GenerateSalt(defaultPasswordConfig.SaltLength)
	passwordHash := utils.HashPassword(req.Password, salt, defaultPasswordConfig)

	user := &domain.User{
		ID:           uuid.New().String(),
		Email:        strings.ToLower(strings.TrimSpace(req.Email)),
		Name:         strings.TrimSpace(req.Name),
		PasswordHash: passwordHash,
		Salt:         salt,
		IsActive:     true,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	if err := a.userRepo.Create(ctx, user); err != nil {
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

	if err != nil || user == nil {
		a.secEventRepo.LogSecurityEvent(ctx, "", types.EventLoginFailed, req.IPAddress, req.UserAgent,
			map[string]interface{}{"reason": "user_not_found"})
		return nil, domain.ErrInvalidCredentials
	}

	// Check if account is locked
	if user.AccountLockedUntil != nil && time.Now().Before(*user.AccountLockedUntil) {
		return nil, domain.ErrAccountLocked
	}

	// Check if account is active
	if !user.IsActive {
		return nil, domain.ErrAccountInactive
	}

	// Verify password
	if !utils.VerifyPassword(req.Password, user.Salt, user.PasswordHash, defaultPasswordConfig) {
		user.FailedLoginCount++
		user.LastFailedLogin = &time.Time{}
		*user.LastFailedLogin = time.Now()

		// Lock account after 5 failed attempts
		if user.FailedLoginCount >= 5 {
			lockUntil := time.Now().Add(time.Hour * 1)
			user.AccountLockedUntil = &lockUntil
			a.secEventRepo.LogSecurityEvent(ctx, user.ID, types.EventAccountLocked, req.IPAddress, req.UserAgent, nil)
		}

		a.userRepo.Update(ctx, user)
		a.secEventRepo.LogSecurityEvent(ctx, user.ID, types.EventLoginFailed, req.IPAddress, req.UserAgent, nil)
		return nil, domain.ErrInvalidCredentials
	}

	// Reset failed login count on successful login
	user.FailedLoginCount = 0
	user.LastFailedLogin = nil
	user.AccountLockedUntil = nil
	user.LastLoginAt = &time.Time{}
	*user.LastLoginAt = time.Now()
	user.LastLoginIP = req.IPAddress
	a.userRepo.Update(ctx, user)

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

	return &dto.LoginResponse{
		AccessToken:  accessToken,
		RefreshToken: session.RefreshToken,
		ExpiresIn:    int64(time.Hour * 24 / time.Second),
	}, nil
}

func (a *authUseCase) generateJWT(userID, sessionID string) (string, error) {
	claims := jwt.MapClaims{
		"user_id":    userID,
		"session_id": sessionID,
		"exp":        time.Now().Add(time.Hour * 24).Unix(),
		"iat":        time.Now().Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(a.jwtSecret))
}
