package usecase

import (
	"context"
	"fmt"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/logger"
	"yefe_app/v1/pkg/utils"

	"github.com/stripe/stripe-go/v74"
	"github.com/stripe/stripe-go/v74/paymentintent"
)

type paymentUseCase struct {
	repo          domain.PaymentRepository
	adminUC       domain.AdminUserUseCase
	paymentConfig utils.Stripe
}

func NewPaymentUseCase(repo domain.PaymentRepository, adminUC domain.AdminUserUseCase, paymentConfig utils.Stripe) domain.PaymentUseCase {
	return &paymentUseCase{repo: repo, adminUC: adminUC, paymentConfig: paymentConfig}
}

func (u *paymentUseCase) CreatePaymentIntent(ctx context.Context, req dto.CreatePaymentIntentRequest) (dto.CreatePaymentIntentResponse, error) {

	// Create payment record
	payment := &domain.Payment{
		ID:            utils.GenerateID(),
		UserID:        req.UserID,
		Amount:        int64(u.paymentConfig.ProPlanPrice) * 1000,
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
		Amount:   stripe.Int64(int64(u.paymentConfig.ProPlanPrice) * 1000),
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

	return dto.CreatePaymentIntentResponse{
		PaymentID:    payment.ID,
		ClientSecret: pi.ClientSecret,
		Amount:       int64(u.paymentConfig.ProPlanPrice) * 1000,
		Currency:     "USD", // TODO make global
		Status:       "pending",
	}, nil
}

func (u *paymentUseCase) ConfirmPayment(ctx context.Context, req dto.ConfirmPaymentRequest) (dto.ConfirmPaymentResponse, error) {
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

	if pi.Status != stripe.PaymentIntentStatusSucceeded {
		return dto.ConfirmPaymentResponse{}, fmt.Errorf("payment not successful: %s", pi.Status)
	}

	// Update payment status
	now := time.Now()
	payment.Status = "completed"
	payment.ProcessedAt = &now
	payment.UpdatedAt = now

	err = u.repo.UpdatePayment(ctx, payment)
	if err != nil {
		return dto.ConfirmPaymentResponse{}, fmt.Errorf("failed to update payment: %w", err)
	}
	err = u.adminUC.UpdateUserPlan(ctx, payment.UserID, "yefe_plus")

	if err != nil {
		logger.Log.WithError(err).Error("Could not update user %s plan", payment.UserID)
		return dto.ConfirmPaymentResponse{}, err
	}
	return dto.ConfirmPaymentResponse{
		PaymentID:   payment.ID,
		Status:      "completed",
		ProcessedAt: now,
		Message:     "Package upgraded successfully",
	}, nil
}

func (u *paymentUseCase) UpgradePackage(ctx context.Context, req dto.UpgradePackageRequest) (dto.UpgradePackageResponse, error) {
	// Create payment intent
	intentReq := dto.CreatePaymentIntentRequest{
		UserID: req.UserID,
	}

	intentResp, err := u.CreatePaymentIntent(ctx, intentReq)
	if err != nil {
		return dto.UpgradePackageResponse{}, err
	}

	return dto.UpgradePackageResponse{
		PaymentID:    intentResp.PaymentID,
		ClientSecret: intentResp.ClientSecret,
		Amount:       intentResp.Amount,
		Message:      "Payment intent created successfully",
	}, nil
}

func (u *paymentUseCase) GetPaymentHistory(ctx context.Context, userID uint, page, limit int) (dto.PaymentHistoryResponse, error) {
	var dtoPayments []dto.Payment
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}

	payments, err := u.repo.GetPaymentsByUserID(ctx, userID, page, limit)
	if err != nil {
		return dto.PaymentHistoryResponse{}, fmt.Errorf("failed to get payment history: %w", err)
	}

	err = utils.TypeConverter(payments, &dtoPayments)
	if err != nil {

		return dto.PaymentHistoryResponse{}, fmt.Errorf("failed to get payment history: %w", err)
	}

	return dto.PaymentHistoryResponse{
		Payments: dtoPayments,
		Total:    int64(len(payments)),
		Page:     page,
		Limit:    limit,
	}, nil
}

func (u *paymentUseCase) ProcessWebhook(ctx context.Context, req dto.WebhookRequest) error {
	switch req.Type {
	case "payment_intent.succeeded":
		// Handle successful payment
		return u.handlePaymentSucceeded(ctx, req.Data)
	case "payment_intent.payment_failed":
		// Handle failed payment
		return u.handlePaymentFailed(ctx, req.Data)
	default:
		logger.Log.Errorf("Unhandled webhook type: %s", req.Type)
	}
	return nil
}

func (u *paymentUseCase) handlePaymentSucceeded(ctx context.Context, data map[string]interface{}) error {
	// Extract payment intent ID from webhook data
	paymentIntentID, ok := data["id"].(string)
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
		logger.Log.WithError(err).Error("Could not update user %s plan", payment.UserID)
		return err
	}

	logger.Log.Info("Payment %s processed successfully via webhook", payment.ID)
	return nil
}

func (u *paymentUseCase) handlePaymentFailed(ctx context.Context, data map[string]interface{}) error {
	// Extract payment intent ID from webhook data
	paymentIntentID, ok := data["id"].(string)
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

	logger.Log.Info("Payment %s marked as failed via webhook", payment.ID)
	return nil
}
