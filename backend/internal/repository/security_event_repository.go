package repository

import (
	"context"
	"fmt"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/infrastructure/db/models"
	"yefe_app/v1/pkg/logger"
	"yefe_app/v1/pkg/types"
	"yefe_app/v1/pkg/utils"

	"gorm.io/gorm"
)

// postgresSecurityEventRepository implements SecurityEventRepository using PostgreSQL
type postgresSecurityEventRepository struct {
	db *gorm.DB
}

// NewpostgresSecurityEventRepository creates a new PostgreSQL security event repository
func NewPostgresSecurityEventRepository(db *gorm.DB) domain.SecurityEventRepository {
	return &postgresSecurityEventRepository{
		db: db,
	}
}

// Create stores a new security event in PostgreSQL
func (r *postgresSecurityEventRepository) Create(ctx context.Context, event *domain.SecurityEvent) error {
	eventModel := r.domainToModel(event)
	if event == nil {
		return fmt.Errorf("event cannot be nil")
	}

	// Validate required fields
	if event.UserID == "" {
		logger.Log.Error("Could not create security event, User ID not provided")
		return fmt.Errorf("userID is required")
	}
	if event.EventType == "" {
		logger.Log.Error("Could not create security event, Event Type not provided")
		return fmt.Errorf("eventType is required")
	}

	// Set timestamps if not already set
	now := time.Now()
	if event.CreatedAt.IsZero() {
		event.CreatedAt = now
	}

	// Create the record
	result := r.db.WithContext(ctx).Create(eventModel)
	if result.Error != nil {
		logger.Log.WithError(result.Error).Error("Could not create security event")
		return fmt.Errorf("failed to create security event: %w", result.Error)
	}

	return nil
}

// GetByUserID retrieves security events for a specific user, ordered by most recent first
func (r *postgresSecurityEventRepository) GetByUserID(ctx context.Context, userID string, limit int) ([]*domain.SecurityEvent, error) {
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
func (r *postgresSecurityEventRepository) GetByUserIDAndType(ctx context.Context, userID, eventType string, limit int) ([]*domain.SecurityEvent, error) {
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
func (r *postgresSecurityEventRepository) GetByUserIDSince(ctx context.Context, userID string, since time.Time, limit int) ([]*domain.SecurityEvent, error) {
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
func (r *postgresSecurityEventRepository) CountByUserID(ctx context.Context, userID string) (int64, error) {
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
func (r *postgresSecurityEventRepository) DeleteOldEvents(ctx context.Context, olderThan time.Duration) error {
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
func (r *postgresSecurityEventRepository) GetRecentSuspiciousActivity(ctx context.Context, eventTypes []string, limit int) ([]*domain.SecurityEvent, error) {
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

func (r *postgresSecurityEventRepository) LogSecurityEvent(ctx context.Context, userID string, eventType types.SecurityEventType, ipAddress, userAgent string, details types.JSONMap) error {
	event := domain.SecurityEvent{
		ID:        utils.GenerateID(),
		UserID:    userID,
		EventType: eventType,
		IPAddress: ipAddress,
		UserAgent: userAgent,
		Details:   details,
		Severity:  types.SeverityInfo,
		CreatedAt: time.Now().UTC(),
	}

	// Don't fail the main operation if logging fails
	err := r.Create(ctx, &event)
	if err != nil {
		logger.Log.WithError(err).Error("Could not log event to database")
	}
	return err
}

func (r *postgresSecurityEventRepository) modelToDomain(event *models.SecurityEvent) *domain.SecurityEvent {
	return &domain.SecurityEvent{
		ID:        event.ID,
		UserID:    event.UserID,
		EventType: event.EventType,
		IPAddress: event.IPAddress,
		UserAgent: event.UserAgent,
		Severity:  event.Severity,
		CreatedAt: event.CreatedAt,
	}
}

func (r *postgresSecurityEventRepository) domainToModel(event *domain.SecurityEvent) *models.SecurityEvent {
	return &models.SecurityEvent{
		ID:        event.ID,
		UserID:    event.UserID,
		EventType: event.EventType,
		IPAddress: event.IPAddress,
		UserAgent: event.UserAgent,
		Details:   event.Details,
		Severity:  event.Severity,
		CreatedAt: event.CreatedAt,
	}
}
