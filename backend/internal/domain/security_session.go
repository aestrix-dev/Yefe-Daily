package domain

import (
	"context"
	"time"
	"yefe_app/v1/pkg/types"
)

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
	UpdatedAt    time.Time `json:"updated_at"`
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
	Details   types.JSONMap           `json:"details"`
	Severity  types.EventSeverity     `json:"severity"`
	CreatedAt time.Time               `json:"created_at"`
}

type SecurityEventRepository interface {
	Create(ctx context.Context, event *SecurityEvent) error
	GetByUserID(ctx context.Context, userID string, limit int) ([]*SecurityEvent, error)
	LogSecurityEvent(ctx context.Context, userID string, eventType types.SecurityEventType, ipAddress, userAgent string, details map[string]interface{}) error
}

// Additional security services
type EmailService interface {
	SendVerificationEmail(user User, token string) error
	SendPasswordResetEmail(user User, token string) error
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
