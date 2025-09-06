package usecase

import (
	"context"
	"time"

	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
)

type sleepUseCase struct {
	sleepRepo domain.SleepRepository
}

func NewSleepUseCase(sleepRepo domain.SleepRepository) domain.SleepUseCase {
	return &sleepUseCase{sleepRepo}
}

func (uc *sleepUseCase) RecordSleep(ctx context.Context, userID string, sleptAt, wokeUpAt time.Time) (*domain.Sleep, error) {
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

func (uc *sleepUseCase) GetUserSleeps(ctx context.Context, userID string) ([]*domain.Sleep, error) {
	return uc.sleepRepo.GetSleepsByUserID(ctx, userID)
}

func (uc *sleepUseCase) GetSleepGraphData(ctx context.Context, userID string, days int) (*dto.SleepGraphResponse, error) {
	sleeps, err := uc.sleepRepo.GetSleepsByUserIDAndDateRange(ctx, userID, time.Now().AddDate(0, 0, -days), time.Now())
	if err != nil {
		return nil, err
	}

	var totalDuration float64
	graphData := make([]dto.SleepGraphData, 0, len(sleeps))
	for _, s := range sleeps {
		duration := s.WokeUpAt.Sub(s.SleptAt).Hours()
		totalDuration += duration
		graphData = append(graphData, dto.SleepGraphData{
			Date:     s.CreatedAt,
			Duration: duration,
			DayOfWeek: s.CreatedAt.Weekday().String(),
		})
	}

	var averageSleepDuration float64
	if len(sleeps) > 0 {
		averageSleepDuration = totalDuration / float64(len(sleeps))
	}

	return &dto.SleepGraphResponse{
		GraphData:            graphData,
		AverageSleepDuration: averageSleepDuration,
		TotalEntries:         len(sleeps),
	}, nil
}
