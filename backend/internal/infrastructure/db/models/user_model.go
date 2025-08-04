package models

import (
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/pkg/types"

	"gorm.io/gorm"
)

type AdminInvitation struct {
	ID              string    `gorm:"primaryKey;autoIncrement" json:"id"`
	Email           string    `gorm:"type:varchar(255);not null;index" json:"email"`
	Role            string    `gorm:"type:varchar(100);not null" json:"role"`
	InvitedBy       string    `gorm:"type:varchar(100)" json:"invited_by"`
	InvitationToken string    `gorm:"type:varchar(255);not null;uniqueIndex" json:"invitation_token"`
	Status          string    `json:"status"`
	ExpiresAt       time.Time `gorm:"autoCreateTime" json:"expires_at"`
	CreatedAt       time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt       time.Time `gorm:"autoUpdateTime" json:"updated_at"`
}

type User struct {
	ID                 string     `gorm:"type:varchar(36);primaryKey" json:"id"`
	Email              string     `gorm:"type:varchar(255);uniqueIndex;not null" json:"email"`
	Name               string     `gorm:"type:varchar(50);not null" json:"name"`
	PasswordHash       string     `gorm:"type:varchar(255);not null" json:"-"`
	Salt               string     `gorm:"type:varchar(255);not null" json:"-"`
	IsEmailVerified    bool       `gorm:"default:false" json:"is_email_verified"`
	IsActive           bool       `gorm:"default:true" json:"is_active"`
	FailedLoginCount   int        `gorm:"default:0" json:"-"`
	LastFailedLogin    *time.Time `gorm:"index" json:"-"`
	AccountLockedUntil *time.Time `gorm:"index" json:"-"`

	Role string `gorm:"type:varchar(20);default:'user';not null" json:"role"`

	// Plan fields embedded directly in user
	PlanType      string     `gorm:"type:varchar(20);default:'free';not null" json:"plan_type"`
	PlanName      string     `gorm:"type:varchar(50);default:'Free';not null" json:"plan_name"`
	PlanStartDate time.Time  `gorm:"default:CURRENT_TIMESTAMP" json:"plan_start_date"`
	PlanEndDate   *time.Time `json:"plan_end_date"`
	PlanAutoRenew bool       `gorm:"default:false" json:"plan_auto_renew"`
	PlanStatus    string     `gorm:"type:varchar(20);default:'active'" json:"plan_status"`

	// Relationships
	Profile        *UserProfile           `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"user_profile,omitempty"`
	Sessions       []domain.Session       `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"-"`
	SecurityEvents []domain.SecurityEvent `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"-"`

	CreatedAt   time.Time      `gorm:"index" json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`
	LastLoginAt *time.Time     `gorm:"index" json:"last_login_at"`
	LastLoginIP string         `gorm:"type:varchar(45)" json:"-"` // IPv6 compatible
}

// UserProfile for extended user information
type UserProfile struct {
	ID                      string                  `gorm:"primaryKey;type:varchar(36)" json:"id"`
	UserID                  string                  `gorm:"uniqueIndex;type:varchar(36);not null" json:"user_id"`
	PhoneNumber             string                  `gorm:"type:varchar(20);index" json:"phone_number"`
	DateOfBirth             *time.Time              `gorm:"type:date" json:"date_of_birth"`
	Gender                  string                  `gorm:"type:varchar(20)" json:"gender"`
	Location                string                  `gorm:"type:varchar(255);index" json:"location"`
	Bio                     string                  `gorm:"type:text" json:"bio"`
	NotificationPreferences types.NotificationsPref `gorm:"embedded;embeddedPrefix:notification_" json:"notification_preferences"`
	CreatedAt               time.Time               `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt               time.Time               `gorm:"autoUpdateTime" json:"updated_at"`
}

// Session model for authentication tokens
type Session struct {
	ID           string        `gorm:"type:varchar(36);primaryKey" json:"id"`
	UserID       string        `gorm:"type:varchar(36);not null;index" json:"user_id"`
	User         User          `gorm:"foreignKey:UserID" json:"-"`
	Token        string        `gorm:"type:varchar(255);uniqueIndex;not null" json:"-"`
	RefreshToken string        `gorm:"type:varchar(255);uniqueIndex;not null" json:"-"`
	ExpiresAt    time.Time     `gorm:"index;not null" json:"expires_at"`
	IPAddress    string        `gorm:"type:varchar(45);index" json:"ip_address"`
	UserAgent    string        `gorm:"type:text" json:"user_agent"`
	IsActive     bool          `gorm:"default:true;index" json:"is_active"`
	LastUsedAt   *time.Time    `gorm:"index" json:"last_used_at"`
	DeviceInfo   types.JSONMap `gorm:"type:jsonb" json:"device_info"`
	CreatedAt    time.Time     `gorm:"index" json:"created_at"`
	UpdatedAt    time.Time     `json:"updated_at"`
}

// SecurityEvent for comprehensive audit logging
type SecurityEvent struct {
	ID         string                  `gorm:"type:varchar(36);primaryKey" json:"id"`
	UserID     string                  `gorm:"type:varchar(36);index" json:"user_id"` // Nullable for anonymous events
	User       *User                   `gorm:"foreignKey:UserID" json:"-"`
	SessionID  string                  `gorm:"type:varchar(36);index" json:"session_id"`
	EventType  types.SecurityEventType `gorm:"type:varchar(50);index;not null" json:"event_type"`
	IPAddress  string                  `gorm:"type:varchar(45);index" json:"ip_address"`
	UserAgent  string                  `gorm:"type:text" json:"user_agent"`
	Details    types.JSONMap           `gorm:"type:jsonb" json:"details"`
	Severity   types.EventSeverity     `gorm:"type:varchar(20);index;default:'info'" json:"severity"`
	Location   string                  `gorm:"type:varchar(255)" json:"location"` // Geolocation
	Resolved   bool                    `gorm:"default:false;index" json:"resolved"`
	ResolvedBy string                  `gorm:"type:varchar(36)" json:"resolved_by"`
	ResolvedAt *time.Time              `json:"resolved_at"`
	CreatedAt  time.Time               `gorm:"index" json:"created_at"`
}
type UserPuzzleProgress struct {
	ID             string     `json:"id" gorm:"primaryKey"`
	UserID         string     `json:"userId" gorm:"not null;index"`
	User           *User      `gorm:"foreignKey:UserID" json:"-"`
	PuzzleID       string     `json:"puzzleId" gorm:"not null;index"`
	IsCompleted    bool       `json:"isCompleted" gorm:"default:false"`
	SelectedAnswer *int       `json:"selectedAnswer,omitempty"`
	IsCorrect      *bool      `json:"isCorrect,omitempty"`
	CompletedAt    *time.Time `json:"completedAt,omitempty"`
	AttemptsCount  int        `json:"attemptsCount" gorm:"default:0"`
	PointsEarned   int        `json:"pointsEarned" gorm:"default:0"`
	CreatedAt      time.Time  `json:"createdAt"`
	UpdatedAt      time.Time  `json:"updatedAt"`
}

// Table name overrides
func (User) TableName() string {
	return "users"
}

func (UserProfile) TableName() string {
	return "user_profiles"
}

func (Session) TableName() string {
	return "sessions"
}

func (j *UserProfile) BeforeCreate(tx *gorm.DB) error {

	return j.NotificationPreferences.Reminders.Validate()
}
