package usecase

import (
	"context"
	"fmt"
	"time"
	"yefe_app/v1/internal/domain"
)

type userActivityUsecase struct {
	securityEventRepo domain.SecurityEventRepository
}

// NewUserActivityUsecase creates a new instance of UserActivityUsecase
func NewUserActivityUsecase(securityEventRepo domain.SecurityEventRepository) domain.UserActivityUsecase {
	return &userActivityUsecase{
		securityEventRepo: securityEventRepo,
	}
}

func (u *userActivityUsecase) GetRecentActivity(ctx context.Context, limit int) ([]domain.SecurityEvent, error) {
	if limit <= 0 {
		limit = 50
	}

	// Get events from the last 7 days
	since := time.Now().AddDate(0, 0, -7)
	events, err := u.securityEventRepo.GetRecentEvents(ctx, since, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get recent events: %w", err)
	}

	return events, nil
}
