package dto

import "time"

type ChallengeDTO struct {
	ID          string    `json:"id"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	Type        string    `json:"type"`
	Points      int       `json:"points"`
	Date        time.Time `json:"date"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// UserChallengeDTO represents a user's challenge interaction in API responses
type UserChallengeDTO struct {
	ID          string     `json:"id"`
	UserID      string     `json:"user_id"`
	ChallengeID string     `json:"challenge_id"`
	Status      string     `json:"status"`
	CompletedAt *time.Time `json:"completed_at,omitempty"`
	CreatedAt   time.Time  `json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`
}

// ChallengeStatsDTO represents user's challenge statistics in API responses
type ChallengeStatsDTO struct {
	UserID          string `json:"user_id"`
	TotalChallenges int    `json:"total_challenges"`
	CompletedCount  int    `json:"completed_count"`
	TotalPoints     int    `json:"total_points"`
	CurrentStreak   int    `json:"current_streak"`
	LongestStreak   int    `json:"longest_streak"`
}

// ChallengeResponse represents the response structure for challenges
type ChallengeResponse struct {
	Challenge     *ChallengeDTO     `json:"challenge"`
	UserChallenge *UserChallengeDTO `json:"user_challenge,omitempty"`
	IsCompleted   bool              `json:"is_completed"`
	CanComplete   bool              `json:"can_complete"`
}

// DashboardResponse represents the user's dashboard data
type DashboardResponse struct {
	TodaysChallenges  ChallengeResponse    `json:"todays_challenges"`
	RecentlyCompleted []ChallengeResponse `json:"recently_completed"`
	Stats             *ChallengeStatsDTO   `json:"stats"`
	CurrentStreak     int                  `json:"current_streak"`
	TotalPoints       int                  `json:"total_points"`
}

// Challenge Status Constants
const (
	StatusPending   = "pending"
	StatusCompleted = "completed"
	StatusSkipped   = "skipped"
)
