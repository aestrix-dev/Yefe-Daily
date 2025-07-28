package repository

import (
	"context"
	"errors"
	"fmt"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/internal/infrastructure/db/models"
	"yefe_app/v1/pkg/logger"
	"yefe_app/v1/pkg/utils"

	"gorm.io/gorm"
)

// adminUserRepository implements AdminUserRepository using GORM
type adminUserRepository struct {
	db       *gorm.DB
	userRepo domain.UserRepository
}

// NewAdminUserRepository creates a new admin user repository
func NewAdminUserRepository(db *gorm.DB, userRepo domain.UserRepository) domain.AdminUserRepository {
	return &adminUserRepository{
		db:       db,
		userRepo: userRepo,
	}
}
func (s *adminUserRepository) GetMonthlyAnylics(ctx context.Context) ([]domain.MonthlyRegistrations, error) {
	var results []domain.MonthlyRegistrations

	err := s.db.Model(&models.User{}).
		Select("TO_CHAR(created_at, 'Mon') AS month, COUNT(DISTINCT id) AS count").
		Group("DATE_TRUNC('month', created_at), month").
		Order("DATE_TRUNC('month', created_at)").
		Scan(&results).Error

	if err != nil {
		return nil, err
	}

	return results, nil
}

// GetAllUsers retrieves all users with filtering and pagination
func (r *adminUserRepository) GetAllUsers(ctx context.Context, filter dto.UserListFilter) (dto.UserListResponse, error) {
	var dbusers []models.User
	var users []dto.User
	var total int64

	// Build the base query
	query := r.db.WithContext(ctx).Model(&models.User{}).Preload("Profile")

	if filter.Role != "" {
		query = query.Where("role = ?", filter.Role)
	}

	// Apply filters
	if filter.Status != "" {
		query = query.Where("status = ?", filter.Status)
	}

	if filter.Plan != "" {
		query = query.Where("plan = ?", filter.Plan)
	}

	if filter.Search != "" {
		search := "%" + filter.Search + "%"
		query = query.Where("name ILIKE ? OR email ILIKE ?", search, search)
	}

	// Get total count
	if err := query.Count(&total).Error; err != nil {
		return dto.UserListResponse{}, err
	}

	// Apply sorting
	sortBy := "created_at"
	if filter.SortBy != "" {
		sortBy = filter.SortBy
	}

	sortOrder := "desc"
	if filter.SortOrder != "" {
		sortOrder = filter.SortOrder
	}

	orderClause := sortBy + " " + sortOrder
	query = query.Order(orderClause)

	// Apply pagination
	if filter.Limit > 0 {
		query = query.Limit(filter.Limit)
	}

	if filter.Offset > 0 {
		query = query.Offset(filter.Offset)
	}

	// Execute query
	if err := query.Find(&dbusers).Error; err != nil {
		return dto.UserListResponse{}, err
	}

	// Calculate pagination info
	totalPages := int(total) / filter.Limit
	if int(total)%filter.Limit != 0 {
		totalPages++
	}

	page := (filter.Offset / filter.Limit) + 1

	err := utils.TypeConverter(dbusers, &users)
	if err != nil {
		return dto.UserListResponse{}, err
	}

	return dto.UserListResponse{
		Users:      users,
		Total:      total,
		Page:       page,
		PageSize:   filter.Limit,
		TotalPages: totalPages,
	}, nil
}

// GetUserStats retrieves user statistics for the admin dashboard
func (r *adminUserRepository) GetUserStats(ctx context.Context) (dto.UserStats, error) {
	var stats dto.UserStats

	// Get total users
	if err := r.db.WithContext(ctx).Model(&models.User{}).Count(&stats.TotalUsers).Error; err != nil {
		return stats, err
	}

	// Get active users
	if err := r.db.WithContext(ctx).Model(&models.User{}).Where("status = ?", "active").Count(&stats.ActiveUsers).Error; err != nil {
		return stats, err
	}

	// Get suspended users
	if err := r.db.WithContext(ctx).Model(&models.User{}).Where("status = ?", "suspended").Count(&stats.SuspendedUsers).Error; err != nil {
		return stats, err
	}

	// Get free users
	if err := r.db.WithContext(ctx).Model(&models.User{}).Where("plan = ?", "free").Count(&stats.FreeUsers).Error; err != nil {
		return stats, err
	}

	// Get paid users
	if err := r.db.WithContext(ctx).Model(&models.User{}).Where("plan != ?", "free").Count(&stats.PaidUsers).Error; err != nil {
		return stats, err
	}

	// Get new users today
	today := time.Now().Truncate(24 * time.Hour)
	if err := r.db.WithContext(ctx).Model(&models.User{}).Where("created_at >= ?", today).Count(&stats.NewUsersToday).Error; err != nil {
		return stats, err
	}

	// Get new users this month
	firstOfMonth := time.Date(time.Now().Year(), time.Now().Month(), 1, 0, 0, 0, 0, time.Local)
	if err := r.db.WithContext(ctx).Model(&models.User{}).Where("created_at >= ?", firstOfMonth).Count(&stats.NewUsersThisMonth).Error; err != nil {
		return stats, err
	}

	return stats, nil
}

// UpdateUserStatus updates a user's status
func (r *adminUserRepository) UpdateUserStatus(ctx context.Context, userID string, status string) error {
	result := r.db.WithContext(ctx).Model(models.User{}).Where("id = ?", userID).Update("status", status)
	if result.Error != nil {
		return result.Error
	}

	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}

	return nil
}

// UpdateUserPlan updates a user's subscription plan
func (r *adminUserRepository) UpdateUserPlan(ctx context.Context, userID string, plan string) error {
	result := r.db.WithContext(ctx).Model(models.User{}).Where("id = ?", userID).Update("plan", plan)
	if result.Error != nil {
		return result.Error
	}

	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}

	return nil
}

func (r *adminUserRepository) InviteAdmin(ctx context.Context, invitation domain.AdminInvitation) error {
	var dbInvitation models.AdminInvitation
	err := utils.TypeConverter(invitation, &dbInvitation)
	if err != nil {
		logger.Log.WithError(err).Error("user domain to model error")
		return err
	}

	if err := r.db.WithContext(ctx).Create(&dbInvitation).Error; err != nil {
		return fmt.Errorf("failed to create admin invitation: %w", err)
	}

	return nil
}

// TODO use where
func (r *adminUserRepository) GetAdminInvitations(ctx context.Context) ([]domain.AdminInvitation, error) {
	var dbinvitations []models.AdminInvitation
	var invitations []domain.AdminInvitation

	if err := r.db.WithContext(ctx).Find(&dbinvitations).Error; err != nil {
		return nil, fmt.Errorf("failed to get admin invitations: %w", err)
	}
	err := utils.TypeConverter(dbinvitations, &invitations)
	if err != nil {
		return nil, err
	}

	return invitations, nil
}

func (r *adminUserRepository) UpdateInvitationStatus(ctx context.Context, invitationID string, status string) error {
	updates := map[string]interface{}{
		"status": status,
	}

	result := r.db.WithContext(ctx).Model(&models.AdminInvitation{}).Where("id = ?", invitationID).Updates(updates)
	if result.Error != nil {
		return fmt.Errorf("failed to update invitation status: %w", result.Error)
	}
	if result.RowsAffected == 0 {
		return fmt.Errorf("invitation not found")
	}
	return nil
}

func (r *adminUserRepository) GetAdminInvitationByID(ctx context.Context, token string) (*domain.AdminInvitation, error) {
	var invitation domain.AdminInvitation
	var dbInvitation models.AdminInvitation
	if token == "" {
		return nil, errors.New("email cannot be empty")
	}
	err := r.db.WithContext(ctx).
		Where("invitation_token = ? AND deleted_at IS NULL", token).
		First(&dbInvitation).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, domain.ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to get user by email: %w", err)
	}

	err = utils.TypeConverter(dbInvitation, &invitation)

	if err != nil {
		return nil, err
	}
	return &invitation, nil

}
