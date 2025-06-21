package models

import (
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/pkg/types"

	"gorm.io/gorm"
)

type User struct {
	ID                 string                 `gorm:"type:varchar(36);primaryKey" json:"id"`
	Email              string                 `gorm:"type:varchar(255);uniqueIndex;not null" json:"email"`
	Name               string                 `gorm:"type:varchar(50);not null" json:"name"`
	PasswordHash       string                 `gorm:"type:varchar(255);not null" json:"-"`
	Salt               string                 `gorm:"type:varchar(255);not null" json:"-"`
	IsEmailVerified    bool                   `gorm:"default:false" json:"is_email_verified"`
	IsActive           bool                   `gorm:"default:true" json:"is_active"`
	FailedLoginCount   int                    `gorm:"default:0" json:"-"`
	LastFailedLogin    *time.Time             `gorm:"index" json:"-"`
	AccountLockedUntil *time.Time             `gorm:"index" json:"-"`
	Profile            *UserProfile           `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"profile,omitempty"`
	Sessions           []domain.Session       `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"-"`
	SecurityEvents     []domain.SecurityEvent `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADEt" json:"-"`
	CreatedAt          time.Time              `gorm:"index" json:"created_at"`
	UpdatedAt          time.Time              `json:"updated_at"`
	DeletedAt          gorm.DeletedAt         `gorm:"index" json:"-"`
	LastLoginAt        *time.Time             `gorm:"index" json:"last_login_at"`
	LastLoginIP        string                 `gorm:"type:varchar(45)" json:"-"` // IPv6 compatible
}

// UserProfile for extended user information
type UserProfile struct {
	ID          string     `gorm:"type:varchar(36);primaryKey" json:"id"`
	UserID      string     `gorm:"type:varchar(36);not null;index" json:"user_id"`
	Name        string     `gorm:"type:varchar(100)" json:"first_name"`
	DateOfBirth *time.Time `json:"date_of_birth"`
	PhoneNumber string     `gorm:"type:varchar(20)" json:"phone_number"`
	Avatar      string     `gorm:"type:text" json:"avatar"` // URL or base64
	Bio         string     `gorm:"type:text" json:"bio"`
	Location    string     `gorm:"type:varchar(255)" json:"location"`
	//	Preferences types.JSONMap `gorm:"type:jsonb" json:"preferences"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
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

type LoginAttempt struct {
	ID         string        `gorm:"type:varchar(36);primaryKey" json:"id"`
	UserID     string        `gorm:"type:varchar(36);index" json:"user_id"` // Nullable for failed attempts
	Email      string        `gorm:"type:varchar(255);index" json:"email"`
	IPAddress  string        `gorm:"type:varchar(45);index" json:"ip_address"`
	UserAgent  string        `gorm:"type:text" json:"user_agent"`
	Success    bool          `gorm:"index" json:"success"`
	FailReason string        `gorm:"type:varchar(100)" json:"fail_reason"`
	DeviceInfo types.JSONMap `gorm:"type:jsonb" json:"device_info"`
	Location   string        `gorm:"type:varchar(255)" json:"location"`
	CreatedAt  time.Time     `gorm:"index" json:"created_at"`
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

// TrustedDevice for device-based security
type TrustedDevice struct {
	ID         string        `gorm:"type:varchar(36);primaryKey" json:"id"`
	UserID     string        `gorm:"type:varchar(36);not null;index" json:"user_id"`
	User       User          `gorm:"foreignKey:UserID" json:"-"`
	DeviceHash string        `gorm:"type:varchar(255);uniqueIndex;not null" json:"device_hash"`
	DeviceName string        `gorm:"type:varchar(255)" json:"device_name"`
	DeviceInfo types.JSONMap `gorm:"type:jsonb" json:"device_info"`
	LastUsedAt time.Time     `gorm:"index" json:"last_used_at"`
	IPAddress  string        `gorm:"type:varchar(45)" json:"ip_address"`
	IsActive   bool          `gorm:"default:true;index" json:"is_active"`
	TrustLevel int           `gorm:"default:1" json:"trust_level"` // 1-5 scale
	CreatedAt  time.Time     `gorm:"index" json:"created_at"`
	UpdatedAt  time.Time     `json:"updated_at"`
}

// Permission system
type Role struct {
	ID          string       `gorm:"type:varchar(36);primaryKey" json:"id"`
	Name        string       `gorm:"type:varchar(100);uniqueIndex;not null" json:"name"`
	Description string       `gorm:"type:text" json:"description"`
	Permissions []Permission `gorm:"many2many:role_permissions" json:"permissions"`
	Users       []User       `gorm:"many2many:user_roles" json:"-"`
	IsSystem    bool         `gorm:"default:false" json:"is_system"` // System roles can't be deleted
	CreatedAt   time.Time    `json:"created_at"`
	UpdatedAt   time.Time    `json:"updated_at"`
}

type Permission struct {
	ID          string    `gorm:"type:varchar(36);primaryKey" json:"id"`
	Name        string    `gorm:"type:varchar(100);uniqueIndex;not null" json:"name"`
	Description string    `gorm:"type:text" json:"description"`
	Resource    string    `gorm:"type:varchar(100);index" json:"resource"`
	Action      string    `gorm:"type:varchar(50);index" json:"action"`
	Roles       []Role    `gorm:"many2many:role_permissions" json:"-"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// Join tables for many-to-many relationships
type UserRole struct {
	UserID    string     `gorm:"type:varchar(36);primaryKey" json:"user_id"`
	RoleID    string     `gorm:"type:varchar(36);primaryKey" json:"role_id"`
	GrantedBy string     `gorm:"type:varchar(36)" json:"granted_by"`
	GrantedAt time.Time  `json:"granted_at"`
	ExpiresAt *time.Time `json:"expires_at"`
}

type RolePermission struct {
	RoleID       string    `gorm:"type:varchar(36);primaryKey" json:"role_id"`
	PermissionID string    `gorm:"type:varchar(36);primaryKey" json:"permission_id"`
	CreatedAt    time.Time `json:"created_at"`
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
func (LoginAttempt) TableName() string {
	return "login_attempts"
}
func (TrustedDevice) TableName() string {
	return "trusted_devices"
}

func (Role) TableName() string {
	return "roles"
}

func (Permission) TableName() string {
	return "permissions"
}

func (UserRole) TableName() string {
	return "user_roles"
}

func (RolePermission) TableName() string {
	return "role_permissions"
}
