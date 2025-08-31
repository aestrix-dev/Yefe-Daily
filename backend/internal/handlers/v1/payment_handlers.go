package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/logger"
	"yefe_app/v1/pkg/utils"

	"github.com/go-chi/chi/v5"
)

type paymentHandler struct {
	usecase         domain.PaymentUseCase
	paymentProvider map[string]domain.PaymentProvider
}

func NewPaymentHandler(usecase domain.PaymentUseCase, paymentProvider map[string]domain.PaymentProvider) *paymentHandler {
	return &paymentHandler{usecase: usecase, paymentProvider: paymentProvider}
}

func (p paymentHandler) Handle() *chi.Mux {
	router := chi.NewRouter()

	router.Post("/intent", p.CreatePaymentIntent)
	router.Post("/verify", p.ConfirmPayment)
	router.Post("/verify/{referenceID}", p.ConfirmPayment)
	router.Get("/history/{user_id}", p.GetPaymentHistory)
	return router
}

func (h *paymentHandler) getProviderFromRequest(r *http.Request) (string, error) {
	provider := strings.ToLower(r.Header.Get("X-Payment-Provider"))

	switch provider {
	case "paystack", "stripe":
		return provider, nil
	default:
		return "", fmt.Errorf("unsupported payment provider: %s", provider)
	}
}

func (h *paymentHandler) CreatePaymentIntent(w http.ResponseWriter, r *http.Request) {
	var req dto.CreatePaymentIntentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", nil)
		return
	}

	provider, err := h.getProviderFromRequest(r)

	if err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, err.Error(), nil)
		return
	}

	paymentPovider, ok := h.paymentProvider[provider]
	if !ok {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid payment provider", nil)

	}

	req.UserID = getUserIDFromContext(r.Context())

	resp, err := paymentPovider.CreatePaymentIntent(r.Context(), req)
	if err != nil {
		logger.Log.WithError(err).Error("Could not create payment intent")
		utils.ErrorResponse(w, http.StatusInternalServerError, "Internal server error", nil)
		return
	}
	utils.SuccessResponse(w, http.StatusCreated, "Payment intent created", resp)
}

func (h *paymentHandler) ConfirmPayment(w http.ResponseWriter, r *http.Request) {
	var req dto.ConfirmPaymentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", nil)
		return
	}

	provider, err := h.getProviderFromRequest(r)

	if err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, err.Error(), nil)
		return
	}

	paymentPovider, ok := h.paymentProvider[provider]
	if !ok {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid payment provider", nil)

	}

	resp, err := paymentPovider.ConfirmPayment(r.Context(), req)
	if err != nil {
		logger.Log.WithError(err).Error("Could not confirm payment")
		utils.ErrorResponse(w, http.StatusInternalServerError, "Internal server error", nil)
		return
	}

	utils.SuccessResponse(w, http.StatusOK, "Payment confirmed", resp)
}
func (h *paymentHandler) UpgradePackage(w http.ResponseWriter, r *http.Request) {
	var req dto.UpgradePackageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", nil)
		return
	}
	provider, err := h.getProviderFromRequest(r)

	if err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, err.Error(), nil)
		return
	}

	paymentPovider, ok := h.paymentProvider[provider]
	if !ok {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid payment provider", nil)

	}
	resp, err := paymentPovider.UpgradePackage(r.Context(), req)
	if err != nil {
		logger.Log.WithError(err).Error("Could not conirm payment")
		utils.ErrorResponse(w, http.StatusInternalServerError, "Internal server error", nil)
		return
	}

	utils.SuccessResponse(w, http.StatusCreated, "Plan Upgrage", resp)
}

func (h *paymentHandler) StripeWebhook(w http.ResponseWriter, r *http.Request) {
	var req dto.WebhookRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		logger.Log.WithError(err).Error("Stripe Decoder error")
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", nil)
		return
	}
	req.Signature = r.Header.Get("Stripe-Signature")

	paymentPovider, ok := h.paymentProvider["stripe"]
	if !ok {
		logger.Log.Error("Stripe payment provider does not exit")
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid payment provider", nil)

	}
	if err := paymentPovider.ProcessWebhook(r.Context(), req); err != nil {
		logger.Log.WithError(err).Error("Could not process Stripe webhook")
		utils.ErrorResponse(w, http.StatusInternalServerError, "Internal server error", nil)
		return
	}
	utils.SuccessResponse(w, http.StatusOK, "Webhook processed", nil)
}

func (h *paymentHandler) PaystackWebhook(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(r.Body)
	if err != nil {
		logger.Log.WithError(err).Error("failed to read request body")
		utils.ErrorResponse(w, http.StatusBadRequest, "invalid request body", nil)
		return
	}
	defer r.Body.Close()

	var req dto.WebhookRequest
	if err := json.Unmarshal(body, &req); err != nil {
		logger.Log.WithError(err).Error("Paystack Decoder Error")
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", nil)
		return
	}

	req.Body = body
	req.Signature = r.Header.Get("X-Paystack-Signature")

	paymentProvider, ok := h.paymentProvider["paystack"]
	if !ok {
		logger.Log.Error("Paystack payment provider does not exit")
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid payment provider", nil)
		return
	}

	if err := paymentProvider.ProcessWebhook(r.Context(), req); err != nil {
		logger.Log.WithError(err).Error("Could not process Paystack webhook")
		utils.ErrorResponse(w, http.StatusInternalServerError, "Internal server error", nil)
		return
	}

	utils.SuccessResponse(w, http.StatusOK, "Webhook processed", nil)
}

func (h *paymentHandler) GetPaymentHistory(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "user_id")
	userIDInt, err := strconv.Atoi(userID)
	if err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid user_id", nil)
		return
	}

	page, err := strconv.Atoi(r.URL.Query().Get("page"))
	if err != nil {
		page = 1
	}

	limit, err := strconv.Atoi(r.URL.Query().Get("limit"))
	if err != nil {
		limit = 10
	}

	resp, err := h.usecase.GetPaymentHistory(r.Context(), uint(userIDInt), page, limit)
	if err != nil {
		logger.Log.WithError(err).Error("Could not get payment history")
		utils.ErrorResponse(w, http.StatusInternalServerError, "Internal server error", nil)
		return
	}

	utils.SuccessResponse(w, http.StatusOK, "Payment history", resp)
}
