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

// Session represents user session
type Session struct {
	ID           string    `json:"id"`
	UserID       string    `json:"user_id"`
	Token        string    `json:"-"`
	RefreshToken string    `json:"-"`
	ExpiresAt    time.Time `json:"expires_at"`
	IPAddress    string    `json:"ip_address"`
	UserAgent    string    `json:"user_agent"`
	IsActive     bool      `json:"is_active"`
	CreatedAt    time.Time `json:"created_at"`
}

// EmailVerificationToken for email verification
type EmailVerificationToken struct {
	ID        string    `json:"id"`
	UserID    string    `json:"user_id"`
	Token     string    `json:"token"`
	ExpiresAt time.Time `json:"expires_at"`
	Used      bool      `json:"used"`
	CreatedAt time.Time `json:"created_at"`
}

// Security events for audit logging
type SecurityEvent struct {
	ID        string                  `json:"id"`
	UserID    string                  `json:"user_id"`
	EventType types.SecurityEventType `json:"event_type"`
	IPAddress string                  `json:"ip_address"`
	UserAgent string                  `json:"user_agent"`
	Details   map[string]any          `json:"details"`
	CreatedAt time.Time               `json:"created_at"`
}

type UserRepository interface {
	Create(ctx context.Context, user *User) error
	GetByID(ctx context.Context, id string) (*User, error)
	GetByEmail(ctx context.Context, email string) (*User, error)
	GetByUsername(ctx context.Context, username string) (*User, error)
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

type SecurityEventRepository interface {
	Create(ctx context.Context, event *SecurityEvent) error
	GetByUserID(ctx context.Context, userID string, limit int) ([]*SecurityEvent, error)
}

type SessionRepository interface {
	Create(ctx context.Context, session *Session) error
	GetByToken(ctx context.Context, token string) (*Session, error)
	GetByUserID(ctx context.Context, userID string) ([]*Session, error)
	Update(ctx context.Context, session *Session) error
	Delete(ctx context.Context, id string) error
	DeleteByUserID(ctx context.Context, userID string) error
	DeleteExpired(ctx context.Context) error
}
