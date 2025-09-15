package repository

import (
	"context"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/pkg/services/fire_base"

	"gorm.io/gorm"
)

type fcmRepository struct {
	db *gorm.DB
}

func NewFCMRepository(db *gorm.DB) domain.FCMRepository {
	return &fcmRepository{db: db}
}

func (r *fcmRepository) GetFCMToken(ctx context.Context, userID string) (string, error) {
	var prefs fire_base.FCMUserPreferences
	if err := r.db.WithContext(ctx).Where("user_id = ?", userID).First(&prefs).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return "", nil // No preferences found for user, so no token.
		}
		return "", err
	}
	return prefs.FCMToken, nil
}
