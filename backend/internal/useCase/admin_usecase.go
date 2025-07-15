package usecase

import (
	"context"
	"errors"
	"fmt"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/logger"
	"yefe_app/v1/pkg/utils"
)

type adminUserUseCase struct {
	adminRepo    domain.AdminUserRepository
	userRepo     domain.UserRepository
	emailService domain.EmailService
}

func NewAdminUserUseCase(
	adminRepo domain.AdminUserRepository,
	userRepo domain.UserRepository,
	emailService domain.EmailService,
) domain.AdminUserUseCase {
	return &adminUserUseCase{
		adminRepo:    adminRepo,
		userRepo:     userRepo,
		emailService: emailService,
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
		endDate := time.Now().AddDate(0, 1, 0)
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

func (uc *adminUserUseCase) InviteNewAdmin(ctx context.Context, invitation dto.AdminInvitationEmailRequest, invitedBy string) error {

	// Check if user already exists
	_, err := uc.userRepo.GetByEmail(ctx, invitation.Email)
	if err == nil {
		return fmt.Errorf("user with email %s already exists", invitation.Email)
	}

	// Generate invitation token
	token := utils.GenerateSecureToken()

	invitaionDomain := domain.AdminInvitation{
		ID:              utils.GenerateID(),
		Email:           invitation.Email,
		Role:            "admin",
		InvitationToken: token,
		Status:          "pending",
		InvitedBy:       invitedBy,
		ExpiresAt:       time.Now().Add(3 * 24 * time.Hour),
	}

	// Create invitation in database
	err = uc.adminRepo.InviteAdmin(ctx, invitaionDomain)
	if err != nil {
		return fmt.Errorf("failed to create admin invitation: %w", err)
	}

	// Send invitation email
	invitationLink := fmt.Sprintf("https://yourapp.com/admin/accept-invitation?token=%s", token)
	emailReq := dto.AdminInvitationEmailResponse{
		AdminInvitationEmailRequest: invitation,
		InvitationLink:              invitationLink,
	}

	err = uc.emailService.SendAdminInvitation(ctx, emailReq)
	if err != nil {
		// If email fails, we should consider rolling back the invitation
		return fmt.Errorf("failed to send invitation email: %w", err)
	}

	return nil
}

func (uc *adminUserUseCase) GetPendingInvitations(ctx context.Context) ([]domain.AdminInvitation, error) {
	invitations, err := uc.adminRepo.GetAdminInvitations(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get admin invitations: %w", err)
	}

	// Filter only pending invitations
	var pendingInvitations []domain.AdminInvitation
	for _, inv := range invitations {
		if inv.Status == "pending" && inv.ExpiresAt.After(time.Now()) {
			pendingInvitations = append(pendingInvitations, inv)
		}
	}

	return pendingInvitations, nil
}

func (uc *adminUserUseCase) AcceptInvitation(ctx context.Context, invitationToken string) error {

	// Get all invitations and find the one with matching token
	invitations, err := uc.adminRepo.GetAdminInvitations(ctx)
	if err != nil {
		return fmt.Errorf("failed to get invitations: %w", err)
	}

	var invitation *domain.AdminInvitation
	for _, inv := range invitations {
		if inv.InvitationToken == invitationToken {
			invitation = &inv
			break
		}
	}

	if invitation == nil {
		return fmt.Errorf("invitation not found")
	}

	// Check if invitation is still valid
	if invitation.Status != "pending" {
		return fmt.Errorf("invitation has already been %s", invitation.Status)
	}

	if invitation.ExpiresAt.Before(time.Now()) {
		// Update status to expired
		uc.adminRepo.UpdateInvitationStatus(ctx, invitation.ID, "expired")
		return fmt.Errorf("invitation has expired")
	}

	// Check if user already exists
	_, err = uc.userRepo.GetByEmail(ctx, invitation.Email)
	if err == nil {
		logger.Log.WithError(err).Error("User already exists")
		return fmt.Errorf("user with email %s already exists", invitation.Email)
	}

	// Create the admin user
	newUser := &domain.User{
		ID:       utils.GenerateID(),
		Email:    invitation.Email,
		Role:     invitation.Role,
		IsActive: true,
	}

	err = uc.userRepo.CreateAdminUser(ctx, newUser, invitation.Role)
	if err != nil {
		logger.Log.WithError(err).Error("Could not create admin account")
		return fmt.Errorf("failed to create admin user: %w", err)
	}

	// Update invitation status to accepted
	err = uc.adminRepo.UpdateInvitationStatus(ctx, invitation.ID, "accepted")
	if err != nil {
		logger.Log.WithError(err).Error("Could not update invitation status")
		return fmt.Errorf("failed to update invitation status: %w", err)
	}

	return nil
}
