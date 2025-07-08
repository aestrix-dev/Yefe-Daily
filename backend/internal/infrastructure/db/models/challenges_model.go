package models

import (
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"

	"gorm.io/gorm"
)

// UserChallenge represents a user's interaction with a challenge
type UserChallenge struct {
	ID          string         `gorm:"primaryKey;type:varchar(36)" json:"id"`
	UserID      string         `gorm:"type:varchar(36);not null;index" json:"user_id"`
	ChallengeID string         `gorm:"type:varchar(36);not null;index" json:"challenge_id"`
	Status      string         `gorm:"type:varchar(20);default:'pending';index" json:"status"`
	CompletedAt *time.Time     `json:"completed_at,omitempty"`
	Notes       string         `gorm:"type:text" json:"notes,omitempty"`
	CreatedAt   time.Time      `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt   time.Time      `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"deleted_at"`

	// Relationships
	Challenge domain.Challenge `gorm:"foreignKey:ChallengeID;constraint:OnDelete:CASCADE" json:"challenge,omitempty"`
	User      User             `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"user,omitempty"`
}

// TableName overrides the table name used by UserChallenge to `user_challenges`
func (UserChallenge) TableName() string {
	return "user_challenges"
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
	LastCompletedAt *time.Time     `json:"last_completed_at,omitempty"`
	StreakStartedAt *time.Time     `json:"streak_started_at,omitempty"`
	CreatedAt       time.Time      `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt       time.Time      `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt       gorm.DeletedAt `gorm:"index" json:"deleted_at"`

	// Relationships
	User User `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE" json:"user"`
}

// TableName overrides the table name used by ChallengeStats to `challenge_stats`
func (ChallengeStats) TableName() string {
	return "challenge_stats"
}

// Helper methods for UserChallenge
func (uc *UserChallenge) IsCompleted() bool {
	return uc.Status == dto.StatusCompleted
}

func (uc *UserChallenge) IsPending() bool {
	return uc.Status == dto.StatusPending
}

func (uc *UserChallenge) IsSkipped() bool {
	return uc.Status == dto.StatusSkipped
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
