package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/logger"
	"yefe_app/v1/pkg/utils"

	"github.com/go-chi/chi/v5"
)

type paymentHandler struct {
	useCase domain.PaymentUseCase
}

func NewPaymentHandler(useCase domain.PaymentUseCase) *paymentHandler {
	return &paymentHandler{useCase: useCase}
}
func (p paymentHandler) Handle() *chi.Mux {
	router := chi.NewRouter()

	router.Post("/intent", p.CreatePaymentIntent)
	router.Post("/confirm", p.ConfirmPayment)
	router.Get("/history/:user_id", p.GetPaymentHistory)
	router.Post("/webhooks/stripe", p.StripeWebhook)
	return router
}
func (h *paymentHandler) CreatePaymentIntent(w http.ResponseWriter, r *http.Request) {
	var req dto.CreatePaymentIntentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Invalid request body", nil)
		return
	}

	resp, err := h.useCase.CreatePaymentIntent(r.Context(), req)
	if err != nil {
		logger.Log.WithError(err).Error("Could not create payment intenet")
		utils.ErrorResponse(w, http.StatusInsufficientStorage, "Internal server error", nil)
		return
	}

	utils.SuccessResponse(w, http.StatusCreated, "new entry created", resp)

}

func (h *paymentHandler) ConfirmPayment(w http.ResponseWriter, r *http.Request) {
	var req dto.ConfirmPaymentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", nil)
		return
	}

	resp, err := h.useCase.ConfirmPayment(r.Context(), req)
	if err != nil {
		logger.Log.WithError(err).Error("Could not conirm payment")
		utils.ErrorResponse(w, http.StatusInsufficientStorage, "Internal server error", nil)
		return
	}

	utils.SuccessResponse(w, http.StatusCreated, "Payment confirmation", resp)
}

func (h *paymentHandler) UpgradePackage(w http.ResponseWriter, r *http.Request) {
	var req dto.UpgradePackageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", nil)
		return
	}

	resp, err := h.useCase.UpgradePackage(r.Context(), req)
	if err != nil {
		logger.Log.WithError(err).Error("Could not conirm payment")
		utils.ErrorResponse(w, http.StatusInternalServerError, "Internal server error", nil)
		return
	}

	utils.SuccessResponse(w, http.StatusCreated, "Plan Upgrage", resp)
}

func (h *paymentHandler) GetPaymentHistory(w http.ResponseWriter, r *http.Request) {
	userID, _ := strconv.Atoi(r.URL.Query().Get("user_id"))
	page, err := strconv.Atoi(r.URL.Query().Get("page"))
	if err != nil {
		page = 1
	}
	limit, err := strconv.Atoi(r.URL.Query().Get("limit"))

	if err != nil {
		limit = 10
	}

	resp, err := h.useCase.GetPaymentHistory(r.Context(), uint(userID), page, limit)
	if err != nil {
		logger.Log.WithError(err).Error("Could not get payment history")
		utils.ErrorResponse(w, http.StatusInternalServerError, "Internal server error", nil)
		return
	}

	utils.SuccessResponse(w, http.StatusCreated, "Payment History", resp)

}

func (h *paymentHandler) StripeWebhook(w http.ResponseWriter, r *http.Request) {
	var req dto.WebhookRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", nil)
		return
	}

	err := h.useCase.ProcessWebhook(r.Context(), req)
	if err != nil {
		logger.Log.WithError(err).Error("Could not process stripe webhook")
		utils.ErrorResponse(w, http.StatusInternalServerError, "Internal server error", nil)
		return
	}

	utils.SuccessResponse(w, http.StatusCreated, "Webhook", nil)
}
