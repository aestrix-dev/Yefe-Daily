package usecase

import (
	"context"
	"time"

	"yefe_app/v1/internal/domain"
)

type sleepUseCase struct {
	sleepRepo domain.SleepRepository
}

func NewSleepUseCase(sleepRepo domain.SleepRepository) domain.SleepUseCase {
	return &sleepUseCase{sleepRepo}
}

func (uc *sleepUseCase) RecordSleep(ctx context.Context, userID uint, sleptAt, wokeUpAt time.Time) (*domain.Sleep, error) {
	sleep := &domain.Sleep{
		UserID:   userID,
		SleptAt:  sleptAt,
		WokeUpAt: wokeUpAt,
	}

	if err := uc.sleepRepo.CreateSleep(ctx, sleep); err != nil {
		return nil, err
	}

	return sleep, nil
}

func (uc *sleepUseCase) GetUserSleeps(ctx context.Context, userID uint) ([]*domain.Sleep, error) {
	return uc.sleepRepo.GetSleepsByUserID(ctx, userID)
}

func (uc *sleepUseCase) GetSleepGraphData(ctx context.Context, userID uint, days int) ([]*domain.Sleep, error) {
	return uc.sleepRepo.GetSleepsByUserIDAndDateRange(ctx, userID, time.Now().AddDate(0, 0, -days), time.Now())
}
