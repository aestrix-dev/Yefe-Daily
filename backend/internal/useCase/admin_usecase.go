package usecase

import (
	"context"
	"errors"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
)

type adminUserUseCase struct {
	adminRepo domain.AdminUserRepository
	userRepo  domain.UserRepository
}

func NewAdminUserUseCase(
	adminRepo domain.AdminUserRepository,
	userRepo domain.UserRepository,
) domain.AdminUserUseCase {
	return &adminUserUseCase{
		adminRepo: adminRepo,
		userRepo:  userRepo,
	}
}

func (uc *adminUserUseCase) GetAllUsers(
	ctx context.Context,
	filter dto.UserListFilter,
) (dto.UserListResponse, error) {
	// Validate pagination parameters
	if filter.Limit < 1 || filter.Limit > 100 {
		filter.Limit = 50 // Default limit
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}

	return uc.adminRepo.GetAllUsers(ctx, filter)
}

func (uc *adminUserUseCase) UpdateUserStatus(
	ctx context.Context,
	userID string,
	status string,
) error {
	// Validate status input
	validStatuses := map[string]bool{"active": true, "suspended": true, "deactivated": true}
	if !validStatuses[status] {
		return domain.ErrInvalidUserStatus
	}

	// Get current user data
	user, err := uc.userRepo.GetByID(ctx, userID)
	if err != nil {
		if errors.Is(err, domain.ErrUserNotFound) {
			return domain.ErrUserNotFound
		}
		return errors.New("failed to fetch user")
	}

	// Prevent redundant updates
	if (status == "active" && user.IsActive) ||
		(status == "suspended" && !user.IsActive) {
		return nil // No change needed
	}

	// Update status
	user.IsActive = (status == "active")

	// Persist changes
	if err := uc.userRepo.Update(ctx, user); err != nil {
		return errors.New("failed to update user status")
	}

	return nil
}

func (uc *adminUserUseCase) UpdateUserPlan(
	ctx context.Context,
	userID string,
	plan string,
) error {
	// Validate plan input
	validPlans := map[string]bool{"free": true, "yefe_plus": true}
	if !validPlans[plan] {
		return domain.ErrInvalidPlanType
	}

	// Get current user data
	user, err := uc.userRepo.GetByID(ctx, userID)
	if err != nil {
		if errors.Is(err, domain.ErrUserNotFound) {
			return domain.ErrUserNotFound
		}
		return errors.New("failed to fetch user")
	}

	// Check if user is in pending state
	if user.PlanStatus == "pending" {
		return domain.ErrPlanUpdateConflict
	}

	// Prevent redundant updates
	if user.PlanType == plan {
		return domain.ErrUserAlreadyHasPlan
	}

	// Business logic for plan changes
	switch {
	case plan == "free" && user.PlanType == "yefe_plus":
		// Downgrade from premium to free
		user.DowngradeToFree()

	case plan == "yefe_plus" && user.PlanType == "free":
		// Upgrade from free to premium
		endDate := time.Now().AddDate(1, 0, 0) // 1 year default
		user.UpgradeToYefePlus(&endDate, true)

	default:
		// Invalid transition (like free to free or yefe_plus to yefe_plus)
		return domain.ErrInvalidPlanTransition
	}

	// Persist changes
	if err := uc.userRepo.Update(ctx, user); err != nil {
		return errors.New("failed to update user plan")
	}

	return nil
}
