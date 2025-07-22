package usecase

import (
	"context"
	"fmt"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/utils"
)

type paymentUseCase struct {
	repo domain.PaymentRepository
}

func NewPaymentUsecase(repo domain.PaymentRepository) domain.PaymentUseCase {
	return &paymentUseCase{repo: repo}
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
