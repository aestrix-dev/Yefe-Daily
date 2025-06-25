package repository

import (
	"context"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/pkg/types"
	"yefe_app/v1/pkg/utils"

	"gorm.io/gorm"
)

// gormUserProfileRepository implements UserProfileRepository
type gormUserProfileRepository struct {
	db *gorm.DB
}

// NewUserProfileRepository creates a new GORM-based user profile repository
func NewUserProfileRepository(db *gorm.DB) domain.UserProfileRepository {
	return &gormUserProfileRepository{
		db: db,
	}
}

// Create creates a new user profile
func (r *gormUserProfileRepository) Create(ctx context.Context, profile *domain.UserProfile) error {
	if profile.ID == "" {
		profile.ID = utils.GenerateID()
	}

	return r.db.WithContext(ctx).Create(profile).Error
}

// GetByID retrieves a user profile by ID
func (r *gormUserProfileRepository) GetByID(ctx context.Context, id string) (*domain.UserProfile, error) {
	var profile domain.UserProfile
	err := r.db.WithContext(ctx).Where("id = ?", id).First(&profile).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &profile, nil
}

// GetByUserID retrieves a user profile by user ID
func (r *gormUserProfileRepository) GetByUserID(ctx context.Context, userID string) (*domain.UserProfile, error) {
	var profile domain.UserProfile
	err := r.db.WithContext(ctx).Where("user_id = ?", userID).First(&profile).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &profile, nil
}

// Update updates a user profile
func (r *gormUserProfileRepository) Update(ctx context.Context, profile *domain.UserProfile) error {

	return r.db.WithContext(ctx).Save(profile).Error
}

// UpdatePartial performs partial updates on a user profile
func (r *gormUserProfileRepository) UpdatePartial(ctx context.Context, id string, updates map[string]interface{}) error {

	result := r.db.WithContext(ctx).Model(&domain.UserProfile{}).Where("id = ?", id).Updates(updates)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// Delete soft deletes a user profile
func (r *gormUserProfileRepository) Delete(ctx context.Context, id string) error {
	result := r.db.WithContext(ctx).Where("id = ?", id).Delete(&domain.UserProfile{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// UpdateAvatar updates the avatar URL for a user
func (r *gormUserProfileRepository) UpdateAvatar(ctx context.Context, userID, avatarURL string) error {
	result := r.db.WithContext(ctx).
		Model(&domain.UserProfile{}).
		Where("user_id = ?", userID).
		Update("avatar_url", avatarURL)

	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// UpdateNotificationPreferences updates notification preferences for a user
func (r *gormUserProfileRepository) UpdateNotificationPreferences(ctx context.Context, userID string, prefs types.NotificationsPref) error {
	updates := map[string]interface{}{
		"notification_morning_prompt":             prefs.MorningPrompt,
		"notification_evening_reflection":         prefs.EveningReflection,
		"notification_challange":                  prefs.Challenge,
		"notification_reminders_morning_reminder": prefs.Reminders.MorningReminder,
		"notification_reminders_evening_reminder": prefs.Reminders.EveningReminder,
	}

	result := r.db.WithContext(ctx).
		Model(&domain.UserProfile{}).
		Where("user_id = ?", userID).
		Updates(updates)

	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// Count returns the total number of user profiles
func (r *gormUserProfileRepository) Count(ctx context.Context) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&domain.UserProfile{}).Count(&count).Error
	return count, err
}

// Exists checks if a user profile exists for the given user ID
func (r *gormUserProfileRepository) Exists(ctx context.Context, userID string) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&domain.UserProfile{}).
		Where("user_id = ?", userID).
		Count(&count).Error

	return count > 0, err
}

// Migration helper - call this to auto-migrate the table
func MigrateUserProfile(db *gorm.DB) error {
	return db.AutoMigrate(&domain.UserProfile{})
}
