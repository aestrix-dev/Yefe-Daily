package domain

import (
	"context"
	"time"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/types"
)

type User struct {
	ID                 string       `json:"id"`
	Email              string       `json:"email"`
	Name               string       `json:"Name"`
	PasswordHash       string       `json:"-"`
	Salt               string       `json:"-"`
	IsEmailVerified    bool         `json:"is_email_verified"`
	IsActive           bool         `json:"is_active"`
	FailedLoginCount   int          `json:"-"`
	LastFailedLogin    *time.Time   `json:"-"`
	AccountLockedUntil *time.Time   `json:"-"`
	CreatedAt          time.Time    `json:"created_at"`
	UpdatedAt          time.Time    `json:"updated_at"`
	LastLoginAt        *time.Time   `json:"last_login_at"`
	LastLoginIP        string       `json:"-"`
	Profile            *UserProfile `json:"user_profile"`
}

type UserProfile struct {
	ID                      string                  `json:"id"`
	UserID                  string                  `json:"user_id"`
	DateOfBirth             *time.Time              `json:"date_of_birth"`
	PhoneNumber             string                  `json:"phone_number"`
	AvatarURL               string                  `json:"avatar_url"`
	Bio                     string                  `json:"bio"`
	Location                string                  `json:"location"`
	NotificationPreferences types.NotificationsPref `json:"notification_preferences"`
	CreatedAt               time.Time               `json:"created_at"`
	UpdatedAt               time.Time               `json:"updated_at"`
}

type UserRepository interface {
	Create(ctx context.Context, user *User, notificationsPrefs types.NotificationsPref) error
	GetByID(ctx context.Context, id string) (*User, error)
	GetByEmail(ctx context.Context, email string) (*User, error)
	Update(ctx context.Context, user *User) error
	Delete(ctx context.Context, id string) error
	UpdateLastLogin(ctx context.Context, userID string) error
}

type UserProfileRepository interface {
	Create(ctx context.Context, profile *UserProfile) error
	GetByID(ctx context.Context, id string) (*UserProfile, error)
	GetByUserID(ctx context.Context, userID string) (*UserProfile, error)
	Update(ctx context.Context, profile *UserProfile) error
	UpdatePartial(ctx context.Context, id string, updates map[string]interface{}) error
	Delete(ctx context.Context, id string) error
	UpdateAvatar(ctx context.Context, userID, avatarURL string) error
	UpdateNotificationPreferences(ctx context.Context, userID string, prefs types.NotificationsPref) error
	Count(ctx context.Context) (int64, error)
	Exists(ctx context.Context, userID string) (bool, error)
}

type AuthUseCase interface {
	Register(ctx context.Context, req dto.RegisterRequest) (*User, error)
	Login(ctx context.Context, req dto.LoginRequest) (*dto.LoginResponse, error)
	Logout(ctx context.Context, req dto.LogoutRequest) error
	//RefreshToken(ctx context.Context, refreshToken string) (*dto.LoginResponse, error)
	//LogoutAll(ctx context.Context, userID string) error
	//VerifyEmail(ctx context.Context, token string) error
	//ForgotPassword(ctx context.Context, email string) error
	//ResetPassword(ctx context.Context, token, newPassword string) error
	//ChangePassword(ctx context.Context, userID, currentPassword, newPassword string) error
}
