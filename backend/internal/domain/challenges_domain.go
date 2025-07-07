package domain

import (
	"time"
)

// Challenge represents a daily challenge for users
type Challenge struct {
	ID          string    `json:"id"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	Type        string    `json:"type"`
	Points      int       `json:"points"`
	Date        time.Time `json:"date"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type ChallengesData struct {
	Challenges []Challenge `json:"challenges"`
}

// UserChallenge represents a user's interaction with a challenge
type UserChallenge struct {
	ID          string     `json:"id"`
	UserID      string     `json:"user_id"`
	ChallengeID string     `json:"challenge_id"`
	Status      string     `json:"status"`
	CompletedAt *time.Time `json:"completed_at,omitempty"`
	CreatedAt   time.Time  `json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`
}

// ChallengeStats represents user's challenge statistics
type ChallengeStats struct {
	UserID          string `json:"user_id"`
	TotalChallenges int    `json:"total_challenges"`
	CompletedCount  int    `json:"completed_count"`
	TotalPoints     int    `json:"total_points"`
	CurrentStreak   int    `json:"current_streak"`
	LongestStreak   int    `json:"longest_streak"`
}

// Repository Interfaces

// ChallengeRepository defines the interface for challenge data operations
type ChallengeRepository interface {
	// Challenge CRUD operations
	GetChallengeByID(id string) (Challenge, error)
	GetChallengesByType(challengeType string, limit int) ([]Challenge, error)
	GetAllChallenges() ([]Challenge, error)
	GetRandomChallange() Challenge
}

// UserChallengeRepository defines the interface for user challenge operations
type UserChallengeRepository interface {
	// User Challenge CRUD operations
	CreateUserChallenge(userChallenge UserChallenge) error
	GetUserChallengeByID(id string) (UserChallenge, error)
	GetUserChallengesByUserID(userID string) ([]UserChallenge, error)
	UpdateUserChallenge(userChallenge UserChallenge) error

	// Get user's challenges by status
	GetUserChallengesByStatus(userID string, status string) ([]UserChallenge, error)

	// Get user's completed challenges
	GetCompletedChallenges(userID string, limit int) ([]UserChallenge, error)

	// Get user's pending challenges
	GetPendingChallenges(userID string) ([]UserChallenge, error)

	// Get user's challenges for today
	GetTodaysUserChallenges(userID string) ([]UserChallenge, error)
}

// ChallengeStatsRepository defines the interface for challenge statistics operations
type ChallengeStatsRepository interface {
	GetUserStats(userID string) (ChallengeStats, error)
	UpdateUserStats(stats ChallengeStats) error
	GetLeaderboard(limit int) ([]ChallengeStats, error)
}

// Use Case Interfaces

// ChallengeUseCase defines the business logic interface for challenges
type ChallengeUseCase interface {
	//GetTodaysChallenges() ([]*Challenge, error)

	GetUserChallengesForToday(userID string) ([]*UserChallenge, error)
	GetUserChallengeHistory(userID string, limit int) ([]UserChallenge, error)

	CompleteChallenge(userID, challengeID string) error
	MarkChallengeAsSkipped(userID, challengeID string) error

	GetUserStats(userID string) (ChallengeStats, error)
	GetUserProgress(userID string, period string) (map[string]any, error)
	GetLeaderboard(limit int) ([]ChallengeStats, error)

	GetAvailableChallengeTypes() ([]string, error)
}

const (
	ChallengeMorningPrayer         = "morning_prayer"
	ChallengeScriptureMemorization = "scripture_memorization"
	ChallengeActsOfService         = "acts_of_service"
	ChallengeManhoodChallenge      = "manhood_challenge"
)
