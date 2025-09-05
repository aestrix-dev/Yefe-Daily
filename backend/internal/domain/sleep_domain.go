package domain

import (
	"context"
	"time"

	"yefe_app/v1/internal/handlers/dto"
)

// Sleep represents a sleep record for a user.
type Sleep struct {
	ID        uint      `json:"id" gorm:"primary_key"`
	UserID    uint      `json:"user_id"`
	SleptAt   time.Time `json:"slept_at"`
	WokeUpAt  time.Time `json:"woke_up_at"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// SleepRepository defines the interface for interacting with sleep data.
type SleepRepository interface {
	CreateSleep(ctx context.Context, sleep *Sleep) error
	GetSleepByID(ctx context.Context, id uint) (*Sleep, error)
	GetSleepsByUserID(ctx context.Context, userID uint) ([]*Sleep, error)
	GetSleepsByUserIDAndDateRange(ctx context.Context, userID uint, startDate, endDate time.Time) ([]*Sleep, error)
}

// SleepUseCase defines the interface for sleep-related business logic.
type SleepUseCase interface {
	RecordSleep(ctx context.Context, userID uint, sleptAt, wokeUpAt time.Time) (*Sleep, error)
	GetUserSleeps(ctx context.Context, userID uint) ([]*Sleep, error)
	GetSleepGraphData(ctx context.Context, userID uint, days int) (*dto.SleepGraphResponse, error)
}
