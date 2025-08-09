package payments

import (
	"context"
	"encoding/json"
	"fmt"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/logger"
	"yefe_app/v1/pkg/types"
	"yefe_app/v1/pkg/utils"
)

type paystackPaymentProvider struct {
	repo           domain.PaymentRepository
	emailService   domain.EmailService
	adminUC        domain.AdminUserUseCase
	paystackClient domain.PaymentProviderClient
	securityRepo   domain.SecurityEventRepository
	paymentConfig  utils.PaymentConfig // Changed from utils.Stripe to more generic name
}

func NewPaystackPaymentProvider(
	repo domain.PaymentRepository,
	emailService domain.EmailService,
	adminUC domain.AdminUserUseCase,
	paystackClient domain.PaymentProviderClient,
	securityRepo domain.SecurityEventRepository,
	paymentConfig utils.PaymentConfig,
) domain.PaymentProvider {
	return &paystackPaymentProvider{
		repo:           repo,
		emailService:   emailService,
		adminUC:        adminUC,
		paystackClient: paystackClient,
		securityRepo:   securityRepo,
		paymentConfig:  paymentConfig,
	}
}

func (uc *paystackPaymentProvider) CreatePaymentIntent(ctx context.Context, req dto.CreatePaymentIntentRequest) (dto.CreatePaymentIntentResponse, error) {
	amount := (int64(uc.paymentConfig.ProPlanPrice) * 1600) * 100
	user, err := uc.adminUC.GetUserByID(ctx, req.UserID)
	if err != nil {
		return dto.CreatePaymentIntentResponse{}, domain.ErrUserNotFound
	}
	paystackReq := dto.PaystackInitializeRequest{
		Email:    user.Email,
		Amount:   amount,
		Currency: "NGN",
    Metadata: make(map[string]any),
	}
	paystackReq.Metadata["UserID"] = req.UserID
	paystackReq.Metadata["FROM"] = "mobile_app"

	paystackResp, err := uc.paystackClient.InitializeTransaction(ctx, paystackReq)
	if err != nil {
		return dto.CreatePaymentIntentResponse{}, fmt.Errorf("failed to initialize Paystack transaction: %w", err)
	}

	// Create payment record
	payment := &domain.Payment{
		ID:              utils.GenerateID(),
		UserID:          req.UserID,
		Amount:          amount,
		Currency:        "NGN",
		Status:          "pending",
		PaymentIntentID: paystackResp.Data.Reference,
		PaymentMethod:   "paystack",
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
	}

	if err := uc.repo.CreatePayment(ctx, payment); err != nil {
		return dto.CreatePaymentIntentResponse{}, fmt.Errorf("failed to create payment record: %w", err)
	}

	return dto.CreatePaymentIntentResponse{
		PaymentID:    payment.ID,
		PaymentRef:   paystackResp.Data.Reference,
		ClientSecret: paystackResp.Data.AccessCode,
		PaymentURL:   paystackResp.Data.AuthorizationURL,
		Status:       payment.Status,
	}, nil
}

func (uc *paystackPaymentProvider) ConfirmPayment(ctx context.Context, req dto.ConfirmPaymentRequest) (dto.ConfirmPaymentResponse, error) {
	// Verify transaction with Paystack
	verifyResp, err := uc.paystackClient.VerifyTransaction(ctx, req.PaymentIntentID)
	if err != nil {
		return dto.ConfirmPaymentResponse{}, fmt.Errorf("failed to verify Paystack transaction: %w", err)
	}
	payment, err := uc.repo.GetPaymentByID(ctx, req.PaymentID)
	if err != nil {
		return dto.ConfirmPaymentResponse{}, fmt.Errorf("payment not found: %w", err)
	}

	// Update payment status based on verification
	var status string
	switch verifyResp.Data.Status {
	case "completed":
		status = "succeeded"
		now := time.Now()
		payment.ProcessedAt = &now
	case "failed":
		status = "failed"
	default:
		status = "processing"
	}

	payment.Status = status
	payment.UpdatedAt = time.Now()

	if err := uc.repo.UpdatePayment(ctx, payment); err != nil {
		return dto.ConfirmPaymentResponse{}, fmt.Errorf("failed to update payment: %w", err)
	}
	err = uc.adminUC.UpdateUserPlan(ctx, payment.UserID, "yefe_plus")

	if err != nil {
		logger.Log.WithError(err).Errorf("Could not update user %s plan", payment.UserID)
		return dto.ConfirmPaymentResponse{}, err
	}
	err = uc.securityRepo.LogSecurityEvent(ctx, payment.UserID, types.EventConfirmPayment, "", "", types.JSONMap{
		"payment_id": payment.ID,
	})

	return dto.ConfirmPaymentResponse{
		PaymentID:   payment.ID,
		Status:      status,
		ProcessedAt: payment.UpdatedAt,
		Message:     "Package upgraded successfully",
	}, nil
}

func (u *paystackPaymentProvider) UpgradePackage(ctx context.Context, req dto.UpgradePackageRequest) (dto.UpgradePackageResponse, error) {
	// Create payment intent
	intentReq := dto.CreatePaymentIntentRequest{
		UserID: req.UserID,
	}

	intentResp, err := u.CreatePaymentIntent(ctx, intentReq)
	if err != nil {
		return dto.UpgradePackageResponse{}, err
	}
	err = u.securityRepo.LogSecurityEvent(ctx, intentReq.UserID, types.EventUpgradePackage, "", "", types.JSONMap{
		"payment_id": intentResp.PaymentID,
	})
	if err != nil {
		logger.Log.WithError(err).Error("Could not log event")
	}
	return dto.UpgradePackageResponse{
		PaymentID:    intentResp.PaymentID,
		ClientSecret: intentResp.ClientSecret,
		Amount:       intentResp.Amount,
		Message:      "Payment intent created successfully",
	}, nil
}
func (uc *paystackPaymentProvider) ProcessWebhook(ctx context.Context, req dto.WebhookRequest) error {
	// Validate webhook signature

	if !uc.paystackClient.ValidateWebhook(req.Body, req.Signature) {
		return fmt.Errorf("invalid webhook signature")
	}

	var event dto.PaystackWebhookEvent
	if err := json.Unmarshal(req.Body, &event); err != nil {
		return fmt.Errorf("failed to unmarshal webhook event: %w", err)
	}

	switch req.Event {
	case "charge.success":
		return uc.handlePaystackChargeSuccess(ctx, event)
	case "charge.failed":
		return uc.handlePaystackChargeFailed(ctx, event)
	default:
		logger.Log.Errorf("Unhandled webhook type: %s", event.Event)
	}
	return nil
}

func (u *paystackPaymentProvider) handlePaystackChargeSuccess(ctx context.Context, event dto.PaystackWebhookEvent) error {
	logger.Log.Info("Paystack payment successful")

	// Get payment by reference ID
	payment, err := u.repo.GetPaymentByPaymentIntentID(ctx, event.Data.Reference)
	if err != nil {
		logger.Log.WithError(err).Errorf("Failed to find payment with reference %s", event.Data.Reference)
		return fmt.Errorf("payment not found: %w", err)
	}

	// Update payment status
	now := time.Now()
	payment.Status = "completed"
	payment.ProcessedAt = &now
	payment.UpdatedAt = now

	if err := u.repo.UpdatePayment(ctx, payment); err != nil {
		logger.Log.WithError(err).Errorf("Failed to update payment %s", payment.ID)
		return fmt.Errorf("failed to update payment: %w", err)
	}

	// Handle package upgrade
	if event.Data.Metadata["PackageID"] != "" {
		err = u.adminUC.UpdateUserPlan(ctx, payment.UserID, "yefe_plus")
		if err != nil {
			logger.Log.WithError(err).Errorf("Could not update user %s plan", payment.UserID)
			return err
		}
	}

	// Get user details for email
	user, err := u.adminUC.GetUserByID(ctx, payment.UserID)
	if err != nil {
		logger.Log.WithError(err).Errorf("Could not get user: %s", payment.UserID)
		return domain.ErrUserNotFound
	}

	// Prepare and send confirmation email
	emailReq := dto.PaymentConfirmationEmailData{
		Name:          user.Name,
		Email:         user.Email,
		Currency:      payment.Currency,
		Status:        payment.Status,
		Date:          payment.UpdatedAt,
		PaymentMethod: payment.PaymentMethod,
		Amount:        int8(payment.Amount / 100), // Convert from kobo to Naira
		PaymentID:     payment.ID,
	}

	err = u.emailService.SendPaymentConfirmationEmail(ctx, emailReq)
	if err != nil {
		logger.Log.WithError(err).Error("could not send payment confirmation email")
		return fmt.Errorf("could not process payment")
	}

	logger.Log.Infof("Payment %s processed successfully via Paystack webhook", payment.ID)

	// Log security event
	err = u.securityRepo.LogSecurityEvent(ctx, payment.UserID, types.EventPaymentSuccessfull, "", "", types.JSONMap{
		"payment_id": payment.ID,
	})
	if err != nil {
		logger.Log.WithError(err).Error("Could not log event")
	}

	return nil
}

func (u *paystackPaymentProvider) handlePaystackChargeFailed(ctx context.Context, event dto.PaystackWebhookEvent) error {
	logger.Log.Info("Paystack payment failed")

	// Get payment by reference ID
	payment, err := u.repo.GetPaymentByPaymentIntentID(ctx, event.Data.Reference)
	if err != nil {
		logger.Log.WithError(err).Errorf("Failed to find payment with reference %s", event.Data.Reference)
		return fmt.Errorf("payment not found: %w", err)
	}

	// Update payment status
	now := time.Now()
	payment.Status = "failed"
	payment.UpdatedAt = now

	if err := u.repo.UpdatePayment(ctx, payment); err != nil {
		logger.Log.WithError(err).Errorf("Failed to update payment %s", payment.ID)
		return fmt.Errorf("failed to update payment: %w", err)
	}

	// Log failure reason
	if event.Data.Message != "" {
		logger.Log.Errorf("Payment %s failed with reason: %s", payment.ID, event.Data.Message)
	}

	// Get user details for email
	user, err := u.adminUC.GetUserByID(ctx, payment.UserID)
	if err != nil {
		logger.Log.WithError(err).Errorf("Could not get user: %s", payment.UserID)
		return fmt.Errorf("could not get user")
	}

	// Prepare and send failure notification email
	emailReq := dto.PaymentConfirmationEmailData{
		Name:          user.Name,
		Email:         user.Email,
		Currency:      payment.Currency,
		Status:        payment.Status,
		Date:          payment.UpdatedAt,
		PaymentMethod: payment.PaymentMethod,
		Amount:        int8(payment.Amount / 100), // Convert from kobo to Naira
		PaymentID:     payment.ID,
	}

	err = u.emailService.SendPaymentConfirmationEmail(ctx, emailReq)
	if err != nil {
		logger.Log.WithError(err).Error("could not send payment confirmation email")
		return fmt.Errorf("could not process payment")
	}

	logger.Log.Infof("Payment %s marked as failed via Paystack webhook", payment.ID)

	// Log security event
	err = u.securityRepo.LogSecurityEvent(ctx, payment.UserID, types.EventPaymentFailed, "", "", types.JSONMap{
		"payment_id": payment.ID,
	})
	if err != nil {
		logger.Log.WithError(err).Error("Could not log event")
	}

	return nil
}
