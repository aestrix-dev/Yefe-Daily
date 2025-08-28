package repository

import (
	"context"
	"time"

	"yefe_app/v1/internal/domain"
	"gorm.io/gorm"
)

type sleepRepository struct {
	db *gorm.DB
}

func NewSleepRepository(db *gorm.DB) domain.SleepRepository {
	return &sleepRepository{db}
}

func (r *sleepRepository) CreateSleep(ctx context.Context, sleep *domain.Sleep) error {
	return r.db.WithContext(ctx).Create(sleep).Error
}

func (r *sleepRepository) GetSleepByID(ctx context.Context, id uint) (*domain.Sleep, error) {
	var sleep domain.Sleep
	if err := r.db.WithContext(ctx).First(&sleep, id).Error; err != nil {
		return nil, err
	}
	return &sleep, nil
}

func (r *sleepRepository) GetSleepsByUserID(ctx context.Context, userID uint) ([]*domain.Sleep, error) {
	var sleeps []*domain.Sleep
	if err := r.db.WithContext(ctx).Where("user_id = ?", userID).Find(&sleeps).Error; err != nil {
		return nil, err
	}
	return sleeps, nil
}

func (r *sleepRepository) GetSleepsByUserIDAndDateRange(ctx context.Context, userID uint, startDate, endDate time.Time) ([]*domain.Sleep, error) {
	var sleeps []*domain.Sleep
	if err := r.db.WithContext(ctx).Where("user_id = ? AND created_at BETWEEN ? AND ?", userID, startDate, endDate).Find(&sleeps).Error; err != nil {
		return nil, err
	}
	return sleeps, nil
}
