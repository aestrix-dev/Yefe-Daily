package types

// Password security configuration
type PasswordConfig struct {
	Memory      uint32
	Iterations  uint32
	Parallelism uint8
	SaltLength  uint32
	KeyLength   uint32
}

type SecurityEventType string

const (
	EventLogin              SecurityEventType = "login"
	EventLoginFailed        SecurityEventType = "login_failed"
	EventLogout             SecurityEventType = "logout"
	EventAccountCreated     SecurityEventType = "account_created"
	EventAccountDeleted     SecurityEventType = "account_deleted"
	EventProfileUpdated     SecurityEventType = "profile_updated"
	EventPasswordChange     SecurityEventType = "password_change"
	EventPasswordReset      SecurityEventType = "password_reset"
	EventAccountLocked      SecurityEventType = "account_locked"
	EventAccountUnlocked    SecurityEventType = "account_unlocked"
	EventSuspiciousActivity SecurityEventType = "suspicious_activity"
)

type EventSeverity string

const (
	SeverityInfo     EventSeverity = "info"
	SeverityWarning  EventSeverity = "warning"
	SeverityError    EventSeverity = "error"
	SeverityCritical EventSeverity = "critical"
)
