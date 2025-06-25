package types

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"time"
)

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
	EventLogoutFailed       SecurityEventType = "logout_failed"
	EventAccountCreated     SecurityEventType = "account_created"
	EventAccountDeleted     SecurityEventType = "account_deleted"
	EventProfileUpdated     SecurityEventType = "profile_updated"
	EventPasswordChange     SecurityEventType = "password_change"
	EventPasswordReset      SecurityEventType = "password_reset"
	EventAccountLocked      SecurityEventType = "account_locked"
	EventAccountUnlocked    SecurityEventType = "account_unlocked"
	EventSuspiciousActivity SecurityEventType = "suspicious_activity"
	EventAuthFailed         SecurityEventType = "authentication_faield"
)

type EventSeverity string

const (
	SeverityInfo     EventSeverity = "info"
	SeverityWarning  EventSeverity = "warning"
	SeverityError    EventSeverity = "error"
	SeverityCritical EventSeverity = "critical"
)

type PasswordChecker interface {
	IsStrong(password string) bool
}

type ReminderRequest struct {
	MorningReminder time.Time `json:"morning_reminder"`
	EveningReminder time.Time `json:"evening_reminder"`
}

type NotificationsPref struct {
	MorningPrompt     bool            `gorm:"default:true" json:"morning_prompt"`
	EveningReflection bool            `gorm:"default:true" json:"evening_reflection"`
	Challenge         bool            `gorm:"default:true" json:"challange"`
	Language          string          `gorm:"default:false" json:"language"`
	Reminders         ReminderRequest `gorm:"embedded;embeddedPrefix:reminders_" json:"reminders"`
}

type JSONMap map[string]any

func (j JSONMap) Value() (driver.Value, error) {
	if j == nil {
		return "{}", nil
	}

	b, err := json.Marshal(j)
	if err != nil {
		return nil, err
	}
	return string(b), nil // 👈 return a string instead of []byte
}

func (j *JSONMap) Scan(value any) error {

	bytes, ok := value.([]byte)
	if !ok {
		return errors.New("type assertion to []byte failed")
	}

	return json.Unmarshal(bytes, j)
}
