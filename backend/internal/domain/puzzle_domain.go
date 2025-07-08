package domain

import (
	"time"
	"yefe_app/v1/internal/handlers/dto"
)

type Puzzle struct {
	ID            string            `json:"id"`
	Title         string            `json:"title"`
	Question      string            `json:"question"`
	Options       map[string]string `json:"options"`
	CorrectAnswer int               `json:"correctAnswer"`
	Difficulty    string            `json:"difficulty"`
	Category      string            `json:"category"`
	Points        int               `json:"points"`
	Explanation   string            `json:"explanation,omitempty"`
}

type UserPuzzleProgress struct {
	ID             string     `json:"id"`
	UserID         string     `json:"userId"`
	PuzzleID       string     `json:"puzzleId"`
	IsCompleted    bool       `json:"isCompleted"`
	SelectedAnswer *int       `json:"selectedAnswer,omitempty"`
	IsCorrect      *bool      `json:"isCorrect,omitempty"`
	CompletedAt    *time.Time `json:"completedAt,omitempty"`
	AttemptsCount  int        `json:"attemptsCount"`
	PointsEarned   int        `json:"pointsEarned"`
	CreatedAt      time.Time  `json:"createdAt"`
	UpdatedAt      time.Time  `json:"updatedAt"`
}

type PuzzleStats struct {
	TotalPuzzles      int     `json:"totalPuzzles"`
	CompletedPuzzles  int     `json:"completedPuzzles"`
	CorrectAnswers    int     `json:"correctAnswers"`
	TotalPointsEarned int     `json:"totalPointsEarned"`
	AverageAccuracy   float64 `json:"averageAccuracy"`
	Streak            int     `json:"streak"`
}

type PuzzleData struct {
	Puzzles []Puzzle `json:"puzzles"`
}

type PuzzleRepository interface {
	GetAllPuzzles() ([]Puzzle, error)
	GetPuzzleByID(string) (*Puzzle, error)
	GetRandomPuzzle() (*Puzzle, error)
}

type UserPuzzleRepository interface {
	CreateUserPuzzleProgress(progress *UserPuzzleProgress) error
	GetUserPuzzleProgressForDate(userID, date string) (*UserPuzzleProgress, error)
	GetUserPuzzleProgress(userID, puzzleID string) (*UserPuzzleProgress, error)
	UpdateUserPuzzleProgress(progress *UserPuzzleProgress) error
	GetUserPuzzleProgressByUserID(userID string) ([]UserPuzzleProgress, error)
	GetUserPuzzleStats(userID string) (*PuzzleStats, error)
	GetUserStreakCount(userID string) (int, error)
}

type PuzzleUseCase interface {
	GetAllPuzzles() ([]Puzzle, error)
	GetRandomPuzzle() (*Puzzle, error)
	GetUserPuzzleProgressForDate(userID, date string) (*UserPuzzleProgress, error)
	GetUserPuzzleProgress(userID, puzzleID string) (*UserPuzzleProgress, error)
	GetUserPuzzleStats(userID string) (*PuzzleStats, error)
	GetUserCompletedPuzzles(userID string) ([]UserPuzzleProgress, error)
	SubmitPuzzleAnswer(userID, puzzleID string, selectedAnswer int) (*dto.PuzzleSubmissionResult, error)
}
