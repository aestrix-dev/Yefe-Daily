package usecase

import (
	"context"
	"fmt"
	"log"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/utils"

	"github.com/google/uuid"
	"github.com/stripe/stripe-go/v74"
	"github.com/stripe/stripe-go/v74/paymentintent"
)

type paymentUseCase struct {
	repo domain.PaymentRepository
}

func NewPaymentUseCase(repo domain.PaymentRepository) domain.PaymentUseCase {
	return &paymentUseCase{repo: repo}
}

func (u *paymentUseCase) CreatePaymentIntent(ctx context.Context, req dto.CreatePaymentIntentRequest) (dto.CreatePaymentIntentResponse, error) {

	// Create payment record
	payment := &domain.Payment{
		ID:            uuid.New().String(),
		UserID:        req.UserID,
		Amount:        5,
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
		Amount:   stripe.Int64(5),
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
		Amount:       5,
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

	// Update user subscription
	subscription := domain.UserSubscription{
		UserID:    payment.UserID,
		Status:    "active",
		StartDate: now,
		EndDate:   now.AddDate(0, 1, 0),
		CreatedAt: now,
		UpdatedAt: now,
	}

	err = u.repo.CreateOrUpdateSubscription(ctx, subscription)
	if err != nil {
		return dto.ConfirmPaymentResponse{}, fmt.Errorf("failed to update subscription: %w", err)
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
		UserID:      req.UserID,
		ToPackageID: req.ToPackageID,
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
		log.Printf("Unhandled webhook type: %s", req.Type)
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
	// This is a simplified approach - you might want to add an index
	// or store the mapping differently
	return nil
}

func (u *paymentUseCase) handlePaymentFailed(ctx context.Context, data map[string]interface{}) error {
	// Similar to handlePaymentSucceeded but update status to failed
	return nil
}
