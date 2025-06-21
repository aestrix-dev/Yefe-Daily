package domain

import (
	"context"
	"time"
	"yefe_app/v1/internal/handlers/dto"
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
	ID          string
	UserID      string
	Name        string
	DateOfBirth *time.Time
	PhoneNumber string
	Avatar      string
	Bio         string
	Location    string
	//	Preferences JSONMap
	CreatedAt time.Time
	UpdatedAt time.Time
}

type UserRepository interface {
	Create(ctx context.Context, user *User) error
	GetByID(ctx context.Context, id string) (*User, error)
	GetByEmail(ctx context.Context, email string) (*User, error)
	Update(ctx context.Context, user *User) error
	Delete(ctx context.Context, id string) error
}

type AuthUseCase interface {
	Register(ctx context.Context, req dto.RegisterRequest) (*User, error)
	Login(ctx context.Context, req dto.LoginRequest) (*dto.LoginResponse, error)
	RefreshToken(ctx context.Context, refreshToken string) (*dto.LoginResponse, error)
	Logout(ctx context.Context, token string) error
	LogoutAll(ctx context.Context, userID string) error
	VerifyEmail(ctx context.Context, token string) error
	ForgotPassword(ctx context.Context, email string) error
	ResetPassword(ctx context.Context, token, newPassword string) error
	ChangePassword(ctx context.Context, userID, currentPassword, newPassword string) error
}
