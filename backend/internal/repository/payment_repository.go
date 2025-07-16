package repository

import (
	"context"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/infrastructure/db/models"
	"yefe_app/v1/pkg/utils"

	"gorm.io/gorm"
)

type paymentRepository struct {
	db *gorm.DB
}

func NewPaymentRepository(db *gorm.DB) domain.PaymentRepository {
	return &paymentRepository{db: db}
}

func (r *paymentRepository) CreatePayment(ctx context.Context, payment *domain.Payment) error {
	var dbPayment models.Payment

	err := utils.TypeConverter(payment, &dbPayment)
	if err != nil {
		return err
	}
	return r.db.WithContext(ctx).Create(&dbPayment).Error
}

func (r *paymentRepository) GetPaymentByID(ctx context.Context, id string) (*domain.Payment, error) {
	var payment domain.Payment
	var dbPayment models.Payment
	err := r.db.WithContext(ctx).
		First(&dbPayment, "id = ?", id).Error
	if err != nil {
		return nil, err
	}
	err = utils.TypeConverter(dbPayment, &payment)
	if err != nil {
		return nil, err
	}
	return &payment, err
}

func (r *paymentRepository) UpdatePayment(ctx context.Context, payment *domain.Payment) error {
	var dbPayment models.Payment

	err := utils.TypeConverter(payment, &dbPayment)
	if err != nil {
		return err
	}
	return r.db.WithContext(ctx).Save(&dbPayment).Error
}

func (r *paymentRepository) GetPaymentsByUserID(ctx context.Context, userID uint, page, limit int) ([]domain.Payment, error) {
	var payments []domain.Payment
	var dbPayments []models.Payment

	offset := (page - 1) * limit

	err := r.db.WithContext(ctx).
		Where("user_id = ?", userID).
		Order("created_at DESC").
		Offset(offset).
		Limit(limit).
		Find(&dbPayments).Error
	if err != nil {
		return nil, err
	}
	err = utils.TypeConverter(payments, &dbPayments)
	if err != nil {
		return nil, err
	}
	return payments, err
}

func (r *paymentRepository) GetPaymentByPaymentIntentID(ctx context.Context, paymentIntentID string) (*domain.Payment, error) {
	var payment domain.Payment
	var dbPayment models.Payment
	err := r.db.WithContext(ctx).
		Where("payment_intent_id = ?", paymentIntentID).
		First(&dbPayment).Error
	err = utils.TypeConverter(dbPayment, &payment)
	if err != nil {
		return nil, err
	}
	return &payment, err
}
