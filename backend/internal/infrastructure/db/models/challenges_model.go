package models

import (
	"time"

	"gorm.io/gorm"
)

// Challenge represents a daily challenge for users
type Challenge struct {
	ID          string         `gorm:"primaryKey;type:varchar(36)" json:"id"`
	Title       string         `gorm:"type:varchar(255);not null" json:"title"`
	Description string         `gorm:"type:text" json:"description"`
	Type        string         `gorm:"type:varchar(50);not null;index" json:"type"`
	Points      int            `gorm:"default:0" json:"points"`
	Date        time.Time      `gorm:"type:date;not null;index" json:"date"`
	IsActive    bool           `gorm:"default:true" json:"is_active"`
	CreatedAt   time.Time      `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt   time.Time      `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"deleted_at"`

	// Relationships
	UserChallenges []UserChallenge `gorm:"foreignKey:ChallengeID;constraint:OnDelete:CASCADE" json:"user_challenges,omitempty"`
}

// TableName overrides the table name used by Challenge to `challenges`
func (Challenge) TableName() string {
	return "challenges"
}

// UserChallenge represents a user's interaction with a challenge
type UserChallenge struct {
	ID          string         `gorm:"primaryKey;type:varchar(36)" json:"id"`
	UserID      string         `gorm:"type:varchar(36);not null;index" json:"user_id"`
	ChallengeID string         `gorm:"type:varchar(36);not null;index" json:"challenge_id"`
	Status      string         `gorm:"type:varchar(20);default:'pending';index" json:"status"`
	CompletedAt *time.Time     `gorm:"type:datetime" json:"completed_at,omitempty"`
	Notes       string         `gorm:"type:text" json:"notes,omitempty"`
	CreatedAt   time.Time      `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt   time.Time      `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"deleted_at"`

	// Relationships
	Challenge Challenge `gorm:"foreignKey:ChallengeID;constraint:OnDelete:CASCADE" json:"challenge,omitempty"`
	User      User      `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"user,omitempty"`
}

// TableName overrides the table name used by UserChallenge to `user_challenges`
func (UserChallenge) TableName() string {
	return "user_challenges"
}

// User represents a user in the system
type User struct {
	ID        string         `gorm:"primaryKey;type:varchar(36)" json:"id"`
	Email     string         `gorm:"type:varchar(255);uniqueIndex;not null" json:"email"`
	Username  string         `gorm:"type:varchar(100);uniqueIndex" json:"username"`
	FirstName string         `gorm:"type:varchar(100)" json:"first_name"`
	LastName  string         `gorm:"type:varchar(100)" json:"last_name"`
	IsActive  bool           `gorm:"default:true" json:"is_active"`
	CreatedAt time.Time      `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time      `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"deleted_at"`

	// Relationships
	UserChallenges []UserChallenge `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"user_challenges,omitempty"`
	ChallengeStats ChallengeStats  `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"challenge_stats,omitempty"`
}

// TableName overrides the table name used by User to `users`
func (User) TableName() string {
	return "users"
}

// ChallengeStats represents user's challenge statistics
type ChallengeStats struct {
	ID              string         `gorm:"primaryKey;type:varchar(36)" json:"id"`
	UserID          string         `gorm:"type:varchar(36);uniqueIndex;not null" json:"user_id"`
	TotalChallenges int            `gorm:"default:0" json:"total_challenges"`
	CompletedCount  int            `gorm:"default:0" json:"completed_count"`
	TotalPoints     int            `gorm:"default:0" json:"total_points"`
	CurrentStreak   int            `gorm:"default:0" json:"current_streak"`
	LongestStreak   int            `gorm:"default:0" json:"longest_streak"`
	LastCompletedAt *time.Time     `gorm:"type:datetime" json:"last_completed_at,omitempty"`
	StreakStartedAt *time.Time     `gorm:"type:datetime" json:"streak_started_at,omitempty"`
	CreatedAt       time.Time      `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt       time.Time      `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt       gorm.DeletedAt `gorm:"index" json:"deleted_at"`

	// Relationships
	User User `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"user,omitempty"`
}

// TableName overrides the table name used by ChallengeStats to `challenge_stats`
func (ChallengeStats) TableName() string {
	return "challenge_stats"
}

// ChallengeType represents different types of challenges
type ChallengeType struct {
	ID          string         `gorm:"primaryKey;type:varchar(36)" json:"id"`
	Name        string         `gorm:"type:varchar(100);uniqueIndex;not null" json:"name"`
	Code        string         `gorm:"type:varchar(50);uniqueIndex;not null" json:"code"`
	Description string         `gorm:"type:text" json:"description"`
	IconName    string         `gorm:"type:varchar(100)" json:"icon_name"`
	Color       string         `gorm:"type:varchar(7)" json:"color"` // Hex color code
	IsActive    bool           `gorm:"default:true" json:"is_active"`
	SortOrder   int            `gorm:"default:0" json:"sort_order"`
	CreatedAt   time.Time      `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt   time.Time      `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"deleted_at"`

	// Relationships
	Challenges []Challenge `gorm:"foreignKey:Type;references:Code;constraint:OnDelete:RESTRICT" json:"challenges,omitempty"`
}

// TableName overrides the table name used by ChallengeType to `challenge_types`
func (ChallengeType) TableName() string {
	return "challenge_types"
}

// UserAchievement represents achievements earned by users
type UserAchievement struct {
	ID            string         `gorm:"primaryKey;type:varchar(36)" json:"id"`
	UserID        string         `gorm:"type:varchar(36);not null;index" json:"user_id"`
	AchievementID string         `gorm:"type:varchar(36);not null;index" json:"achievement_id"`
	EarnedAt      time.Time      `gorm:"type:datetime;not null" json:"earned_at"`
	CreatedAt     time.Time      `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt     time.Time      `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt     gorm.DeletedAt `gorm:"index" json:"deleted_at"`

	// Relationships
	User        User        `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"user,omitempty"`
	Achievement Achievement `gorm:"foreignKey:AchievementID;constraint:OnDelete:CASCADE" json:"achievement,omitempty"`
}

// TableName overrides the table name used by UserAchievement to `user_achievements`
func (UserAchievement) TableName() string {
	return "user_achievements"
}

// Achievement represents achievements that users can earn
type Achievement struct {
	ID          string         `gorm:"primaryKey;type:varchar(36)" json:"id"`
	Name        string         `gorm:"type:varchar(255);not null" json:"name"`
	Description string         `gorm:"type:text" json:"description"`
	IconName    string         `gorm:"type:varchar(100)" json:"icon_name"`
	BadgeColor  string         `gorm:"type:varchar(7)" json:"badge_color"`
	Points      int            `gorm:"default:0" json:"points"`
	Criteria    string         `gorm:"type:text" json:"criteria"` // JSON string with criteria
	IsActive    bool           `gorm:"default:true" json:"is_active"`
	SortOrder   int            `gorm:"default:0" json:"sort_order"`
	CreatedAt   time.Time      `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt   time.Time      `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"deleted_at"`

	// Relationships
	UserAchievements []UserAchievement `gorm:"foreignKey:AchievementID;constraint:OnDelete:CASCADE" json:"user_achievements,omitempty"`
}

// TableName overrides the table name used by Achievement to `achievements`
func (Achievement) TableName() string {
	return "achievements"
}

// ChallengeTemplate represents reusable challenge templates
type ChallengeTemplate struct {
	ID          string         `gorm:"primaryKey;type:varchar(36)" json:"id"`
	Title       string         `gorm:"type:varchar(255);not null" json:"title"`
	Description string         `gorm:"type:text" json:"description"`
	Type        string         `gorm:"type:varchar(50);not null;index" json:"type"`
	Points      int            `gorm:"default:0" json:"points"`
	IsActive    bool           `gorm:"default:true" json:"is_active"`
	CreatedAt   time.Time      `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt   time.Time      `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"deleted_at"`
}

// TableName overrides the table name used by ChallengeTemplate to `challenge_templates`
func (ChallengeTemplate) TableName() string {
	return "challenge_templates"
}

// Constants for challenge types
const (
	ChallengeMorningPrayer         = "morning_prayer"
	ChallengeScriptureMemorization = "scripture_memorization"
	ChallengeActsOfService         = "acts_of_service"
	ChallengeManhoodChallenge      = "manhood_challenge"
)

// Constants for challenge status
const (
	StatusPending   = "pending"
	StatusCompleted = "completed"
	StatusSkipped   = "skipped"
)

// BeforeCreate hook for Challenge to generate UUID
func (c *Challenge) BeforeCreate(tx *gorm.DB) error {
	if c.ID == "" {
		// You can use UUID library here, for example:
		// c.ID = uuid.New().String()
		// For now, using a placeholder - replace with actual UUID generation
		c.ID = generateUUID()
	}
	return nil
}

// BeforeCreate hook for UserChallenge to generate UUID
func (uc *UserChallenge) BeforeCreate(tx *gorm.DB) error {
	if uc.ID == "" {
		uc.ID = generateUUID()
	}
	return nil
}

// BeforeCreate hook for User to generate UUID
func (u *User) BeforeCreate(tx *gorm.DB) error {
	if u.ID == "" {
		u.ID = generateUUID()
	}
	return nil
}

// BeforeCreate hook for ChallengeStats to generate UUID
func (cs *ChallengeStats) BeforeCreate(tx *gorm.DB) error {
	if cs.ID == "" {
		cs.ID = generateUUID()
	}
	return nil
}

// BeforeCreate hook for ChallengeType to generate UUID
func (ct *ChallengeType) BeforeCreate(tx *gorm.DB) error {
	if ct.ID == "" {
		ct.ID = generateUUID()
	}
	return nil
}

// BeforeCreate hook for UserAchievement to generate UUID
func (ua *UserAchievement) BeforeCreate(tx *gorm.DB) error {
	if ua.ID == "" {
		ua.ID = generateUUID()
	}
	return nil
}

// BeforeCreate hook for Achievement to generate UUID
func (a *Achievement) BeforeCreate(tx *gorm.DB) error {
	if a.ID == "" {
		a.ID = generateUUID()
	}
	return nil
}

// BeforeCreate hook for ChallengeTemplate to generate UUID
func (ct *ChallengeTemplate) BeforeCreate(tx *gorm.DB) error {
	if ct.ID == "" {
		ct.ID = generateUUID()
	}
	return nil
}

// Placeholder UUID generation function
// Replace this with actual UUID generation using a library like github.com/google/uuid
func generateUUID() string {
	// This is a placeholder - implement proper UUID generation
	// Example: return uuid.New().String()
	return "placeholder-uuid"
}

// Helper methods for UserChallenge
func (uc *UserChallenge) IsCompleted() bool {
	return uc.Status == StatusCompleted
}

func (uc *UserChallenge) IsPending() bool {
	return uc.Status == StatusPending
}

func (uc *UserChallenge) IsSkipped() bool {
	return uc.Status == StatusSkipped
}

// Helper methods for ChallengeStats
func (cs *ChallengeStats) CompletionRate() float64 {
	if cs.TotalChallenges == 0 {
		return 0
	}
	return float64(cs.CompletedCount) / float64(cs.TotalChallenges) * 100
}

func (cs *ChallengeStats) AveragePointsPerChallenge() float64 {
	if cs.CompletedCount == 0 {
		return 0
	}
	return float64(cs.TotalPoints) / float64(cs.CompletedCount)
}
