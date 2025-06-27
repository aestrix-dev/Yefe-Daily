package types

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
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
	MorningReminder time.Time `json:"notification_reminders_morning_reminder"`
	EveningReminder time.Time `json:"notification_reminders_evening_reminder"`
}

type NotificationsPref struct {
	MorningPrompt     bool            `gorm:"default:true" json:"notification_morning_prompt"`
	EveningReflection bool            `gorm:"default:true" json:"notification_evening_reflection"`
	Challenge         bool            `gorm:"default:true" json:"notification_challange"`
	Language          string          `gorm:"default:false" json:"notification_language"`
	Reminders         ReminderRequest `gorm:"embedded;embeddedPrefix:reminders_" json:"notification_reminders"`
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

type Tags []string

// Value implements the driver.Valuer interface (for saving to DB)
func (t Tags) Value() (driver.Value, error) {
	if len(t) == 0 {
		return "", nil
	}
	return strings.Join(t, ","), nil
}

// Scan implements the sql.Scanner interface (for reading from DB)
func (t *Tags) Scan(value any) error {
	if value == nil {
		*t = Tags{}
		return nil
	}

	strVal, ok := value.(string)
	if !ok {
		return fmt.Errorf("failed to scan Tags: value is not a string")
	}

	// Handle empty string case
	if strVal == "" {
		*t = Tags{}
	} else {
		*t = strings.Split(strVal, ",")
	}

	return nil
}
