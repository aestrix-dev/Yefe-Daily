package repository

import (
	"context"
	"yefe_app/v1/internal/domain"

	"gorm.io/gorm"
)

type paymentRepository struct {
	db *gorm.DB
}

func NewPaymentRepository(db *gorm.DB) domain.PaymentRepository {
	return &paymentRepository{db: db}
}

func (r *paymentRepository) CreatePayment(ctx context.Context, payment *domain.Payment) error {
	return r.db.WithContext(ctx).Create(payment).Error
}

// TODO remove the package side
func (r *paymentRepository) GetPaymentByID(ctx context.Context, id string) (*domain.Payment, error) {
	var payment domain.Payment
	err := r.db.WithContext(ctx).
		Preload("FromPackage").
		Preload("ToPackage").
		First(&payment, "id = ?", id).Error
	return &payment, err
}

func (r *paymentRepository) UpdatePayment(ctx context.Context, payment *domain.Payment) error {
	return r.db.WithContext(ctx).Save(payment).Error
}

func (r *paymentRepository) GetPaymentsByUserID(ctx context.Context, userID uint, page, limit int) ([]domain.Payment, error) {
	var payments []domain.Payment
	offset := (page - 1) * limit

	err := r.db.WithContext(ctx).
		Preload("FromPackage").
		Preload("ToPackage").
		Where("user_id = ?", userID).
		Order("created_at DESC").
		Offset(offset).
		Limit(limit).
		Find(&payments).Error

	return payments, err
}

func (r *paymentRepository) GetUserSubscription(ctx context.Context, userID uint) (*domain.UserSubscription, error) {
	var subscription domain.UserSubscription
	err := r.db.WithContext(ctx).
		Preload("Package").
		Where("user_id = ?", userID).
		First(&subscription).Error
	return &subscription, err
}

func (r *paymentRepository) CreateOrUpdateSubscription(ctx context.Context, subscription domain.UserSubscription) error {
	return r.db.WithContext(ctx).Save(&subscription).Error
}

// TODO remove packae here
