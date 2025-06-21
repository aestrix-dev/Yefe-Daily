package repository

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/infrastructure/db/models"
	"yefe_app/v1/pkg/types"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type userRepository struct {
	db *gorm.DB
}

// NewUserRepository creates a new user repository instance
func NewUserRepository(db *gorm.DB) domain.UserRepository {
	return &userRepository{
		db: db,
	}
}

// Create creates a new user in the database
func (r *userRepository) Create(ctx context.Context, user *domain.User) error {
	if user == nil {
		return errors.New("user cannot be nil")
	}

	// Convert domain user to database model
	dbUser := r.domainToModel(user)

	// Use transaction for data consistency
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		// Create user
		if err := tx.Create(dbUser).Error; err != nil {
			if r.isDuplicateError(err) {
				if strings.Contains(err.Error(), "email") {
					return domain.ErrEmailAlreadyExists
				}
			}
			return fmt.Errorf("failed to create user: %w", err)
		}

		// Create default user profile
		profile := &models.UserProfile{
			ID:        generateID(),
			UserID:    dbUser.ID,
			CreatedAt: time.Now().UTC(),
			UpdatedAt: time.Now().UTC(),
		}

		if err := tx.Create(profile).Error; err != nil {
			return fmt.Errorf("failed to create user profile: %w", err)
		}

		// Log security event
		r.logSecurityEvent(ctx, tx, dbUser.ID, types.EventAccountCreated, "", "", nil)

		return nil
	})
}

// GetByID retrieves a user by their ID
func (r *userRepository) GetByID(ctx context.Context, id string) (*domain.User, error) {
	if id == "" {
		return nil, errors.New("id cannot be empty")
	}

	var dbUser models.User
	err := r.db.WithContext(ctx).
		Preload("Profile").
		Where("id = ? AND deleted_at IS NULL", id).
		First(&dbUser).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, domain.ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to get user by id: %w", err)
	}

	return r.modelToDomain(&dbUser), nil
}

// GetByEmail retrieves a user by their email address
func (r *userRepository) GetByEmail(ctx context.Context, email string) (*domain.User, error) {
	if email == "" {
		return nil, errors.New("email cannot be empty")
	}

	// Normalize email
	email = strings.ToLower(strings.TrimSpace(email))

	var dbUser models.User
	err := r.db.WithContext(ctx).
		Preload("Profile").
		Where("email = ? AND deleted_at IS NULL", email).
		First(&dbUser).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, domain.ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to get user by email: %w", err)
	}

	return r.modelToDomain(&dbUser), nil
}

// GetByUsername retrieves a user by their username
func (r *userRepository) GetByUsername(ctx context.Context, username string) (*domain.User, error) {
	if username == "" {
		return nil, errors.New("username cannot be empty")
	}

	// Normalize username
	username = strings.TrimSpace(username)

	var dbUser models.User
	err := r.db.WithContext(ctx).
		Preload("Profile").
		Where("username = ? AND deleted_at IS NULL", username).
		First(&dbUser).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, domain.ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to get user by username: %w", err)
	}

	return r.modelToDomain(&dbUser), nil
}

// GetByEmailOrUsername retrieves a user by email or username
func (r *userRepository) GetByEmailOrUsername(ctx context.Context, identifier string) (*domain.User, error) {
	if identifier == "" {
		return nil, errors.New("identifier cannot be empty")
	}

	identifier = strings.TrimSpace(identifier)

	var dbUser models.User
	var err error

	if strings.Contains(identifier, "@") {
		// It's an email
		err = r.db.WithContext(ctx).
			Preload("Profile").
			Where("email = ? AND deleted_at IS NULL", strings.ToLower(identifier)).
			First(&dbUser).Error
	} else {
		// It's a username
		err = r.db.WithContext(ctx).
			Preload("Profile").
			Where("username = ? AND deleted_at IS NULL", identifier).
			First(&dbUser).Error
	}

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, domain.ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to get user by identifier: %w", err)
	}

	return r.modelToDomain(&dbUser), nil
}

// Update updates an existing user
func (r *userRepository) Update(ctx context.Context, user *domain.User) error {
	if user == nil {
		return errors.New("user cannot be nil")
	}

	if user.ID == "" {
		return errors.New("user ID cannot be empty")
	}

	dbUser := r.domainToModel(user)
	dbUser.UpdatedAt = time.Now().UTC()

	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		// Update user
		result := tx.Model(&models.User{}).
			Where("id = ? AND deleted_at IS NULL", user.ID).
			Updates(dbUser)

		if result.Error != nil {
			if r.isDuplicateError(result.Error) {
				if strings.Contains(result.Error.Error(), "email") {
					return domain.ErrEmailAlreadyExists
				}
				if strings.Contains(result.Error.Error(), "username") {
					return domain.ErrUsernameAlreadyExists
				}
			}
			return fmt.Errorf("failed to update user: %w", result.Error)
		}

		if result.RowsAffected == 0 {
			return domain.ErrUserNotFound
		}

		// Log security event for sensitive updates
		if r.isSensitiveUpdate(user) {
			r.logSecurityEvent(ctx, tx, user.ID, types.EventProfileUpdated, "", "", nil)
		}

		return nil
	})
}

// Delete soft deletes a user
func (r *userRepository) Delete(ctx context.Context, id string) error {
	if id == "" {
		return errors.New("id cannot be empty")
	}

	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		// Soft delete user
		result := tx.Delete(&models.User{}, "id = ?", id)
		if result.Error != nil {
			return fmt.Errorf("failed to delete user: %w", result.Error)
		}

		if result.RowsAffected == 0 {
			return domain.ErrUserNotFound
		}

		// Deactivate all sessions
		tx.Model(&models.Session{}).
			Where("user_id = ?", id).
			Update("is_active", false)

		// Log security event
		r.logSecurityEvent(ctx, tx, id, types.EventAccountDeleted, "", "", nil)

		return nil
	})
}

// UpdatePassword updates user password with security measures
func (r *userRepository) UpdatePassword(ctx context.Context, userID, passwordHash, salt string) error {
	if userID == "" || passwordHash == "" || salt == "" {
		return errors.New("userID, passwordHash, and salt cannot be empty")
	}

	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		result := tx.Model(&models.User{}).
			Where("id = ? AND deleted_at IS NULL", userID).
			Updates(map[string]interface{}{
				"password_hash":        passwordHash,
				"salt":                 salt,
				"updated_at":           time.Now().UTC(),
				"failed_login_count":   0, // Reset failed attempts
				"last_failed_login":    nil,
				"account_locked_until": nil,
			})

		if result.Error != nil {
			return fmt.Errorf("failed to update password: %w", result.Error)
		}

		if result.RowsAffected == 0 {
			return domain.ErrUserNotFound
		}

		// Invalidate all sessions except current one (if provided)
		tx.Model(&models.Session{}).
			Where("user_id = ?", userID).
			Update("is_active", false)

		// Log security event
		r.logSecurityEvent(ctx, tx, userID, domain.EventPasswordChange, "", "", nil)

		return nil
	})
}

// UpdateLastLogin updates user's last login information
func (r *userRepository) UpdateLastLogin(ctx context.Context, userID, ipAddress string) error {
	if userID == "" {
		return errors.New("userID cannot be empty")
	}

	now := time.Now().UTC()
	result := r.db.WithContext(ctx).
		Model(&models.User{}).
		Where("id = ? AND deleted_at IS NULL", userID).
		Updates(map[string]interface{}{
			"last_login_at":        &now,
			"last_login_ip":        ipAddress,
			"failed_login_count":   0,
			"last_failed_login":    nil,
			"account_locked_until": nil,
			"updated_at":           now,
		})

	if result.Error != nil {
		return fmt.Errorf("failed to update last login: %w", result.Error)
	}

	if result.RowsAffected == 0 {
		return domain.ErrUserNotFound
	}

	return nil
}

// IncrementFailedLogin increments failed login count
func (r *userRepository) IncrementFailedLogin(ctx context.Context, userID string) error {
	if userID == "" {
		return errors.New("userID cannot be empty")
	}

	now := time.Now().UTC()

	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		var user models.User
		if err := tx.Where("id = ?", userID).First(&user).Error; err != nil {
			return fmt.Errorf("failed to get user: %w", err)
		}

		user.FailedLoginCount++
		user.LastFailedLogin = &now
		user.UpdatedAt = now

		// Lock account after 5 failed attempts for 1 hour
		if user.FailedLoginCount >= 5 {
			lockUntil := now.Add(time.Hour)
			user.AccountLockedUntil = &lockUntil

			// Log account locked event
			r.logSecurityEvent(ctx, tx, userID, domain.EventAccountLocked, "", "",
				map[string]interface{}{
					"failed_attempts": user.FailedLoginCount,
					"locked_until":    lockUntil,
				})
		}

		if err := tx.Save(&user).Error; err != nil {
			return fmt.Errorf("failed to increment failed login: %w", err)
		}

		return nil
	})
}

// IsEmailTaken checks if an email is already taken
func (r *userRepository) IsEmailTaken(ctx context.Context, email string, excludeUserID ...string) (bool, error) {
	if email == "" {
		return false, errors.New("email cannot be empty")
	}

	email = strings.ToLower(strings.TrimSpace(email))

	query := r.db.WithContext(ctx).
		Model(&models.User{}).
		Where("email = ? AND deleted_at IS NULL", email)

	if len(excludeUserID) > 0 && excludeUserID[0] != "" {
		query = query.Where("id != ?", excludeUserID[0])
	}

	var count int64
	err := query.Count(&count).Error
	if err != nil {
		return false, fmt.Errorf("failed to check email: %w", err)
	}

	return count > 0, nil
}

// IsUsernameTaken checks if a username is already taken
func (r *userRepository) IsUsernameTaken(ctx context.Context, username string, excludeUserID ...string) (bool, error) {
	if username == "" {
		return false, errors.New("username cannot be empty")
	}

	username = strings.TrimSpace(username)

	query := r.db.WithContext(ctx).
		Model(&models.User{}).
		Where("username = ? AND deleted_at IS NULL", username)

	if len(excludeUserID) > 0 && excludeUserID[0] != "" {
		query = query.Where("id != ?", excludeUserID[0])
	}

	var count int64
	err := query.Count(&count).Error
	if err != nil {
		return false, fmt.Errorf("failed to check username: %w", err)
	}

	return count > 0, nil
}

// GetActiveUsers retrieves active users with pagination
func (r *userRepository) GetActiveUsers(ctx context.Context, limit, offset int) ([]*domain.User, int64, error) {
	var users []models.User
	var total int64

	// Count total active users
	if err := r.db.WithContext(ctx).
		Model(&models.User{}).
		Where("is_active = ? AND deleted_at IS NULL", true).
		Count(&total).Error; err != nil {
		return nil, 0, fmt.Errorf("failed to count users: %w", err)
	}

	// Get users with pagination
	if err := r.db.WithContext(ctx).
		Preload("Profile").
		Where("is_active = ? AND deleted_at IS NULL", true).
		Order("created_at DESC").
		Limit(limit).
		Offset(offset).
		Find(&users).Error; err != nil {
		return nil, 0, fmt.Errorf("failed to get users: %w", err)
	}

	// Convert to domain models
	domainUsers := make([]*domain.User, len(users))
	for i, user := range users {
		domainUsers[i] = r.modelToDomain(&user)
	}

	return domainUsers, total, nil
}

// SearchUsers searches users by email or username
func (r *userRepository) SearchUsers(ctx context.Context, query string, limit, offset int) ([]*domain.User, int64, error) {
	if query == "" {
		return r.GetActiveUsers(ctx, limit, offset)
	}

	searchTerm := "%" + strings.ToLower(strings.TrimSpace(query)) + "%"

	var users []models.User
	var total int64

	// Count matching users
	if err := r.db.WithContext(ctx).
		Model(&models.User{}).
		Where("(LOWER(email) LIKE ? OR LOWER(username) LIKE ?) AND is_active = ? AND deleted_at IS NULL",
			searchTerm, searchTerm, true).
		Count(&total).Error; err != nil {
		return nil, 0, fmt.Errorf("failed to count search results: %w", err)
	}

	// Get matching users
	if err := r.db.WithContext(ctx).
		Preload("Profile").
		Where("(LOWER(email) LIKE ? OR LOWER(username) LIKE ?) AND is_active = ? AND deleted_at IS NULL",
			searchTerm, searchTerm, true).
		Order("created_at DESC").
		Limit(limit).
		Offset(offset).
		Find(&users).Error; err != nil {
		return nil, 0, fmt.Errorf("failed to search users: %w", err)
	}

	// Convert to domain models
	domainUsers := make([]*domain.User, len(users))
	for i, user := range users {
		domainUsers[i] = r.modelToDomain(&user)
	}

	return domainUsers, total, nil
}

// Helper methods

// domainToModel converts domain user to database model
func (r *userRepository) domainToModel(user *domain.User) *models.User {
	return &models.User{
		ID:                 user.ID,
		Email:              user.Email,
		Username:           user.Username,
		PasswordHash:       user.PasswordHash,
		Salt:               user.Salt,
		IsEmailVerified:    user.IsEmailVerified,
		IsActive:           user.IsActive,
		FailedLoginCount:   user.FailedLoginCount,
		LastFailedLogin:    user.LastFailedLogin,
		AccountLockedUntil: user.AccountLockedUntil,
		CreatedAt:          user.CreatedAt,
		UpdatedAt:          user.UpdatedAt,
		LastLoginAt:        user.LastLoginAt,
		LastLoginIP:        user.LastLoginIP,
	}
}

// modelToDomain converts database model to domain user
func (r *userRepository) modelToDomain(user *models.User) *domain.User {
	domainUser := &domain.User{
		ID:                 user.ID,
		Email:              user.Email,
		Name:               user.Name,
		PasswordHash:       user.PasswordHash,
		Salt:               user.Salt,
		IsEmailVerified:    user.IsEmailVerified,
		IsActive:           user.IsActive,
		FailedLoginCount:   user.FailedLoginCount,
		LastFailedLogin:    user.LastFailedLogin,
		AccountLockedUntil: user.AccountLockedUntil,
		CreatedAt:          user.CreatedAt,
		UpdatedAt:          user.UpdatedAt,
		LastLoginAt:        user.LastLoginAt,
		LastLoginIP:        user.LastLoginIP,
	}

	// Include profile if loaded
	if user.Profile != nil {
		domainUser.Profile = &domain.UserProfile{
			ID:          user.Profile.ID,
			Name:        user.Profile.Name,
			DateOfBirth: user.Profile.DateOfBirth,
			PhoneNumber: user.Profile.PhoneNumber,
			Avatar:      user.Profile.Avatar,
			Bio:         user.Profile.Bio,
			Location:    user.Profile.Location,
		}
	}

	return domainUser
}

// isDuplicateError checks if error is due to duplicate key constraint
func (r *userRepository) isDuplicateError(err error) bool {
	if err == nil {
		return false
	}

	errStr := strings.ToLower(err.Error())
	return strings.Contains(errStr, "duplicate") ||
		strings.Contains(errStr, "unique") ||
		strings.Contains(errStr, "already exists")
}

// isSensitiveUpdate checks if update contains sensitive fields
func (r *userRepository) isSensitiveUpdate(user *domain.User) bool {
	// Add logic to determine if update is sensitive
	// For now, we'll log all updates
	return true
}

// logSecurityEvent logs a security event
func (r *userRepository) logSecurityEvent(ctx context.Context, tx *gorm.DB, userID string, eventType types.SecurityEventType, ipAddress, userAgent string, details map[string]interface{}) {
	event := &models.SecurityEvent{
		ID:        generateID(),
		UserID:    userID,
		EventType: types.SecurityEventType(eventType),
		IPAddress: ipAddress,
		UserAgent: userAgent,
		Details:   models.JSONMap(details),
		Severity:  types.SeverityInfo,
		CreatedAt: time.Now().UTC(),
	}

	// Don't fail the main operation if logging fails
	tx.Create(event)
}

// generateID generates a new UUID
func generateID() string {
	// Implementation depends on your UUID library
	// Using Google's UUID library as example
	return uuid.New().String()
}
