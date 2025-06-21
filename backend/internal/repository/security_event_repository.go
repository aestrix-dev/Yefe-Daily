package repository

import (
	"context"
	"fmt"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/infrastructure/db/models"
	"yefe_app/v1/pkg/types"
	"yefe_app/v1/pkg/utils"

	"gorm.io/gorm"
)

// PostgresSecurityEventRepository implements SecurityEventRepository using PostgreSQL
type PostgresSecurityEventRepository struct {
	db *gorm.DB
}

// NewPostgresSecurityEventRepository creates a new PostgreSQL security event repository
func NewPostgresSecurityEventRepository(db *gorm.DB) *PostgresSecurityEventRepository {
	return &PostgresSecurityEventRepository{
		db: db,
	}
}

// Create stores a new security event in PostgreSQL
func (r *PostgresSecurityEventRepository) Create(ctx context.Context, event *domain.SecurityEvent) error {
	if event == nil {
		return fmt.Errorf("event cannot be nil")
	}

	// Validate required fields
	if event.UserID == "" {
		return fmt.Errorf("userID is required")
	}
	if event.EventType == "" {
		return fmt.Errorf("eventType is required")
	}

	// Set timestamps if not already set
	now := time.Now()
	if event.CreatedAt.IsZero() {
		event.CreatedAt = now
	}

	// Create the record
	result := r.db.WithContext(ctx).Create(event)
	if result.Error != nil {
		return fmt.Errorf("failed to create security event: %w", result.Error)
	}

	return nil
}

// GetByUserID retrieves security events for a specific user, ordered by most recent first
func (r *PostgresSecurityEventRepository) GetByUserID(ctx context.Context, userID string, limit int) ([]*domain.SecurityEvent, error) {
	if userID == "" {
		return nil, fmt.Errorf("userID cannot be empty")
	}

	// Set reasonable limits
	if limit <= 0 {
		limit = 50 // Default limit
	}
	if limit > 1000 {
		limit = 1000 // Maximum limit to prevent abuse
	}

	var events []*domain.SecurityEvent

	result := r.db.WithContext(ctx).
		Where("user_id = ?", userID).
		Order("created_at DESC").
		Limit(limit).
		Find(&events)

	if result.Error != nil {
		return nil, fmt.Errorf("failed to get security events for user %s: %w", userID, result.Error)
	}

	return events, nil
}

// Additional helper methods that might be useful

// GetByUserIDAndType retrieves security events for a user filtered by event type
func (r *PostgresSecurityEventRepository) GetByUserIDAndType(ctx context.Context, userID, eventType string, limit int) ([]*domain.SecurityEvent, error) {
	if userID == "" {
		return nil, fmt.Errorf("userID cannot be empty")
	}
	if eventType == "" {
		return nil, fmt.Errorf("eventType cannot be empty")
	}

	if limit <= 0 {
		limit = 50
	}
	if limit > 1000 {
		limit = 1000
	}

	var events []*domain.SecurityEvent

	result := r.db.WithContext(ctx).
		Where("user_id = ? AND event_type = ?", userID, eventType).
		Order("created_at DESC").
		Limit(limit).
		Find(&events)

	if result.Error != nil {
		return nil, fmt.Errorf("failed to get security events for user %s and type %s: %w", userID, eventType, result.Error)
	}

	return events, nil
}

// GetByUserIDSince retrieves security events for a user since a specific time
func (r *PostgresSecurityEventRepository) GetByUserIDSince(ctx context.Context, userID string, since time.Time, limit int) ([]*domain.SecurityEvent, error) {
	if userID == "" {
		return nil, fmt.Errorf("userID cannot be empty")
	}

	if limit <= 0 {
		limit = 50
	}
	if limit > 1000 {
		limit = 1000
	}

	var events []*domain.SecurityEvent

	result := r.db.WithContext(ctx).
		Where("user_id = ? AND created_at >= ?", userID, since).
		Order("created_at DESC").
		Limit(limit).
		Find(&events)

	if result.Error != nil {
		return nil, fmt.Errorf("failed to get security events for user %s since %v: %w", userID, since, result.Error)
	}

	return events, nil
}

// CountByUserID returns the total count of security events for a user
func (r *PostgresSecurityEventRepository) CountByUserID(ctx context.Context, userID string) (int64, error) {
	if userID == "" {
		return 0, fmt.Errorf("userID cannot be empty")
	}

	var count int64
	result := r.db.WithContext(ctx).
		Model(&domain.SecurityEvent{}).
		Where("user_id = ?", userID).
		Count(&count)

	if result.Error != nil {
		return 0, fmt.Errorf("failed to count security events for user %s: %w", userID, result.Error)
	}

	return count, nil
}

// DeleteOldEvents removes security events older than the specified duration
func (r *PostgresSecurityEventRepository) DeleteOldEvents(ctx context.Context, olderThan time.Duration) error {
	cutoffTime := time.Now().Add(-olderThan)

	result := r.db.WithContext(ctx).
		Where("created_at < ?", cutoffTime).
		Delete(&domain.SecurityEvent{})

	if result.Error != nil {
		return fmt.Errorf("failed to delete old security events: %w", result.Error)
	}

	return nil
}

// GetRecentSuspiciousActivity gets recent suspicious activities across all users
// This could be useful for admin dashboards
func (r *PostgresSecurityEventRepository) GetRecentSuspiciousActivity(ctx context.Context, eventTypes []string, limit int) ([]*domain.SecurityEvent, error) {
	if len(eventTypes) == 0 {
		eventTypes = []string{string(types.EventLoginFailed), string(types.EventAccountLocked), string(types.EventSuspiciousActivity)}
	}

	if limit <= 0 {
		limit = 100
	}
	if limit > 1000 {
		limit = 1000
	}

	var events []*domain.SecurityEvent

	result := r.db.WithContext(ctx).
		Where("event_type IN ?", eventTypes).
		Order("created_at DESC").
		Limit(limit).
		Find(&events)

	if result.Error != nil {
		return nil, fmt.Errorf("failed to get recent suspicious activity: %w", result.Error)
	}

	return events, nil
}

func (r *PostgresSecurityEventRepository) LogSecurityEvent(ctx context.Context, userID string, eventType types.SecurityEventType, ipAddress, userAgent string, details map[string]interface{}) error {
	event := domain.SecurityEvent{
		ID:        utils.GenerateID(),
		UserID:    userID,
		EventType: types.SecurityEventType(eventType),
		IPAddress: ipAddress,
		UserAgent: userAgent,
		Details:   models.JSONMap(details),
		Severity:  types.SeverityInfo,
		CreatedAt: time.Now().UTC(),
	}

	// Don't fail the main operation if logging fails
	return r.Create(ctx, &event)
}
