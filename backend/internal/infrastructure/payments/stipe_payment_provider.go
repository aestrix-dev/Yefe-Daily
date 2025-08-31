package payments

import (
	"context"
	"fmt"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/logger"
	"yefe_app/v1/pkg/types"
	"yefe_app/v1/pkg/utils"

	"github.com/stripe/stripe-go/v74"
	"github.com/stripe/stripe-go/v74/paymentintent"
)

type stripePaymentProvider struct {
	repo          domain.PaymentRepository
	adminUC       domain.AdminUserUseCase
	paymentConfig utils.PaymentConfig
	emailService  domain.EmailService
	securityRepo  domain.SecurityEventRepository
}

func NewStripePaymentProvider(repo domain.PaymentRepository, adminUC domain.AdminUserUseCase, paymentConfig utils.PaymentConfig, emailSerice domain.EmailService, securityRepo domain.SecurityEventRepository) domain.PaymentProvider {
	return &stripePaymentProvider{repo: repo, adminUC: adminUC, paymentConfig: paymentConfig, emailService: emailSerice, securityRepo: securityRepo}
}

func (u *stripePaymentProvider) CreatePaymentIntent(ctx context.Context, req dto.CreatePaymentIntentRequest) (dto.CreatePaymentIntentResponse, error) {

	// Create payment record
	payment := &domain.Payment{
		ID:            utils.GenerateID(),
		UserID:        req.UserID,
		Amount:        int64(u.paymentConfig.ProPlanPrice) * 100,
		Currency:      "USD",
		Status:        "pending",
		PaymentMethod: req.PaymentMethod,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	}

	err := u.repo.CreatePayment(ctx, payment)
	if err != nil {
		return dto.CreatePaymentIntentResponse{}, fmt.Errorf("failed to create payment: %w", err)
	}

	// Create Stripe payment intent
	params := &stripe.PaymentIntentParams{
		Amount:   stripe.Int64(int64(u.paymentConfig.ProPlanPrice) * 100),
		Currency: stripe.String("USD"),
	}

	pi, err := paymentintent.New(params)
	if err != nil {
		return dto.CreatePaymentIntentResponse{}, fmt.Errorf("failed to create payment intent: %w", err)
	}

	// Update payment with Stripe payment intent ID
	payment.PaymentIntentID = pi.ID
	err = u.repo.UpdatePayment(ctx, payment)
	if err != nil {
		return dto.CreatePaymentIntentResponse{}, fmt.Errorf("failed to update payment: %w", err)
	}
	err = u.securityRepo.LogSecurityEvent(ctx, payment.UserID, types.EventCreatePaymentIntent, "", "", types.JSONMap{
		"payment_id": payment.ID,
	})
	if err != nil {
		logger.Log.WithError(err).Error("Could not log event")
	}
	return dto.CreatePaymentIntentResponse{
		PaymentID:    payment.ID,
		ClientSecret: pi.ClientSecret,
		Amount:       int64(u.paymentConfig.ProPlanPrice) * 100,
		Currency:     "USD", // TODO make global
		Status:       "pending",
		PaymentRef:   payment.PaymentIntentID,
	}, nil
}
func (u *stripePaymentProvider) ConfirmPayment(ctx context.Context, req dto.ConfirmPaymentRequest) (dto.ConfirmPaymentResponse, error) {
	// Get payment
	payment, err := u.repo.GetPaymentByID(ctx, req.PaymentID)
	if err != nil {
		return dto.ConfirmPaymentResponse{}, fmt.Errorf("payment not found: %w", err)
	}

	// Verify payment intent with Stripe
	pi, err := paymentintent.Get(req.PaymentIntentID, nil)
	if err != nil {
		return dto.ConfirmPaymentResponse{}, fmt.Errorf("failed to get payment intent: %w", err)
	}

	// Update payment status
	now := time.Now()
	return dto.ConfirmPaymentResponse{
		PaymentID:   payment.ID,
		Status:      string(pi.Status),
		ProcessedAt: now,
		Message:     "Payment",
	}, nil
}

func (u *stripePaymentProvider) UpgradePackage(ctx context.Context, req dto.UpgradePackageRequest) (dto.UpgradePackageResponse, error) {
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
func (u *stripePaymentProvider) ProcessWebhook(ctx context.Context, req dto.WebhookRequest) error {
	logger.Log.Errorf("webhook type: %s", req.Type)
	switch req.Type {
	case "payment_intent.succeeded":
		// Handle successful payment
		return u.handlePaymentSucceeded(ctx, req.Data)
	case "payment_intent.payment_failed":
		// Handle failed payment
		return u.handlePaymentFailed(ctx, req.Data)
	case "payment_intent.created":
		return nil
	default:
		logger.Log.Errorf("Unhandled webhook type: %s", req.Type)
	}
	return nil
}

func (u *stripePaymentProvider) handlePaymentSucceeded(ctx context.Context, data map[string]interface{}) error {
	logger.Log.Info("Payment successfull")
	// Extract payment intent ID from webhook data
	object, ok := data["object"].(map[string]interface{})
	if !ok {
		return fmt.Errorf("object key is missing or wrong type")
	}

	paymentIntentID, ok := object["id"].(string)
	if !ok {
		return fmt.Errorf("invalid payment intent ID")
	}

	// Find payment by payment intent ID
	payment, err := u.repo.GetPaymentByPaymentIntentID(ctx, paymentIntentID)
	if err != nil {
		logger.Log.WithError(err).Errorf("Failed to find payment with intent ID %s", paymentIntentID)
		return fmt.Errorf("payment not found: %w", err)
	}

	// Update payment status to completed
	now := time.Now()
	payment.Status = "completed"
	payment.ProcessedAt = &now
	payment.UpdatedAt = now

	// Save the updated payment
	if err := u.repo.UpdatePayment(ctx, payment); err != nil {
		logger.Log.WithError(err).Errorf("Failed to update payment %s", payment.ID)
		return fmt.Errorf("failed to update payment: %w", err)
	}

	err = u.adminUC.UpdateUserPlan(ctx, payment.UserID, "yefe_plus")

	if err != nil {
		logger.Log.WithError(err).Errorf("Could not update user %s plan", payment.UserID)
		return err
	}

	user, err := u.adminUC.GetUserByID(ctx, payment.UserID)
	if err != nil {
		logger.Log.WithError(err).Errorf("Could not get user: %s", payment.UserID)
		return fmt.Errorf("Could not get user")
	}

	emailReq := dto.PaymentConfirmationEmailData{
		Name:          user.Name,
		Email:         user.Email,
		Currency:      payment.Currency,
		Status:        payment.Status,
		Date:          payment.UpdatedAt,
		PaymentMethod: payment.PaymentMethod,
		Amount:        int8(payment.Amount / 100),
		PaymentID:     payment.ID,
	}
	err = u.emailService.SendPaymentConfirmationEmail(ctx, emailReq)
	if err != nil {
		logger.Log.WithError(err).Error("could not send payment confirmation email")
		return fmt.Errorf("Could not process payment")
	}
	logger.Log.Infof("Payment %s processed successfully via webhook", payment.ID)
	err = u.securityRepo.LogSecurityEvent(ctx, payment.UserID, types.EventPaymentSuccessfull, "", "", types.JSONMap{
		"payment_id": payment.ID,
	})
	if err != nil {
		logger.Log.WithError(err).Error("Could not log event")
	}
	return nil
}

func (u *stripePaymentProvider) handlePaymentFailed(ctx context.Context, data map[string]interface{}) error {
	logger.Log.Info("Payment failed")
	// Extract payment intent ID from webhook data
	object, ok := data["object"].(map[string]interface{})
	if !ok {
		return fmt.Errorf("object key is missing or wrong type")
	}

	paymentIntentID, ok := object["id"].(string)
	if !ok {
		return fmt.Errorf("invalid payment intent ID")
	}

	// Extract failure reason if available
	var failureReason string
	if lastPaymentError, exists := data["last_payment_error"]; exists {
		if errorMap, ok := lastPaymentError.(map[string]interface{}); ok {
			if message, exists := errorMap["message"]; exists {
				if messageStr, ok := message.(string); ok {
					failureReason = messageStr
				}
			}
		}
	}

	// Find payment by payment intent ID
	payment, err := u.repo.GetPaymentByPaymentIntentID(ctx, paymentIntentID)
	if err != nil {
		logger.Log.WithError(err).Errorf("Failed to find payment with intent ID %s", paymentIntentID)
		return fmt.Errorf("payment not found: %w", err)
	}

	// Update payment status to failed
	now := time.Now()
	payment.Status = "failed"
	payment.UpdatedAt = now

	// Store failure reason if available (assuming you have a FailureReason field)
	// If you don't have this field, you can remove this section
	if failureReason != "" {
		// payment.FailureReason = failureReason
		logger.Log.Errorf("Payment %s failed with reason: %s", payment.ID, failureReason)
	}

	// Save the updated payment
	if err := u.repo.UpdatePayment(ctx, payment); err != nil {
		logger.Log.WithError(err).Errorf("Failed to update payment %s", payment.ID)
		return fmt.Errorf("failed to update payment: %w", err)
	}

	user, err := u.adminUC.GetUserByID(ctx, payment.UserID)
	if err != nil {
		logger.Log.WithError(err).Errorf("Could not get user: %s", payment.UserID)
		return domain.ErrUserNotFound
	}
	emailReq := dto.PaymentConfirmationEmailData{
		Name:          user.Name,
		Email:         user.Email,
		Currency:      payment.Currency,
		Status:        payment.Status,
		Date:          payment.UpdatedAt,
		PaymentMethod: payment.PaymentMethod,
		Amount:        int8(payment.Amount / 100),
		PaymentID:     payment.ID,
	}
	err = u.emailService.SendPaymentConfirmationEmail(ctx, emailReq)
	if err != nil {
		logger.Log.WithError(err).Error("could not send payment confirmation email")
		return fmt.Errorf("Could not process payment")
	}
	logger.Log.Infof("Payment %s marked as failed via webhook", payment.ID)
	err = u.securityRepo.LogSecurityEvent(ctx, payment.UserID, types.EventPaymentFailed, "", "", types.JSONMap{
		"payment_id": payment.ID,
	})
	if err != nil {
		logger.Log.WithError(err).Error("Could not log event")
	}

	return nil
}

// TODO check users plan before creating payment intent
