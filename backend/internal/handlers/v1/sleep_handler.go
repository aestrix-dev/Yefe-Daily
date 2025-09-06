package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"
	"yefe_app/v1/pkg/logger"

	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/utils"

	"github.com/go-chi/chi/v5"
)

// SleepHandler handles HTTP requests for sleep.
type SleepHandler struct {
	sleepUseCase domain.SleepUseCase
}

// NewSleepHandler creates a new SleepHandler.
func NewSleepHandler(sleepUseCase domain.SleepUseCase) *SleepHandler {
	return &SleepHandler{sleepUseCase}
}

// RegisterRoutes registers the sleep routes.
func (h *SleepHandler) RegisterRoutes(r chi.Router) {
	r.Post("/sleep", h.recordSleep)
	r.Get("/sleep", h.getUserSleeps)
	r.Get("/sleep/graph", h.getSleepGraphData)
}

func (h *SleepHandler) recordSleep(w http.ResponseWriter, r *http.Request) {
	var req dto.RecordSleepRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		logger.Log.WithError(err).Error("Failed to decode request payload for recordSleep")
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request payload", nil)
		return
	}

	userID := getUserIDFromContext(r.Context())

	// Combine date and time strings and parse them
	sleptAt, err := time.Parse("2006-01-02 15:04:05", req.SleptDate+" "+req.SleptTime)
	if err != nil {
		logger.Log.WithField("slept_at", req.SleptDate+" "+req.SleptTime).WithError(err).Error("Invalid slept_at format")
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid format for slept_at. Use YYYY-MM-DD and HH:MM:SS", nil)
		return
	}

	wokeUpAt, err := time.Parse("2006-01-02 15:04:05", req.WokeUpDate+" "+req.WokeUpTime)
	if err != nil {
		logger.Log.WithField("woke_up_at", req.WokeUpDate+" "+req.WokeUpTime).WithError(err).Error("Invalid woke_up_at format")
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid format for woke_up_at. Use YYYY-MM-DD and HH:MM:SS", nil)
		return
	}

	sleep, err := h.sleepUseCase.RecordSleep(r.Context(), userID, sleptAt, wokeUpAt)
	if err != nil {
		logger.Log.WithField("user_id", userID).WithError(err).Error("Failed to record sleep")
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to record sleep", nil)
		return
	}

	utils.JSONResponse(w, http.StatusCreated, sleep)
}

func (h *SleepHandler) getUserSleeps(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())

	sleeps, err := h.sleepUseCase.GetUserSleeps(r.Context(), userID)
	if err != nil {
		logger.Log.WithField("user_id", userID).WithError(err).Error("Failed to get user sleeps")
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to get user sleeps", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, sleeps)
}

func (h *SleepHandler) getSleepGraphData(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())
	days := 7 // default to 7 days
	daysStr := r.URL.Query().Get("days")
	if daysStr != "" {
		var err error
		days, err = strconv.Atoi(daysStr)
		if err != nil {
			logger.Log.WithField("days", daysStr).WithError(err).Error("Invalid 'days' query parameter")
			utils.ErrorResponse(w, http.StatusBadRequest, "Invalid 'days' query parameter. It must be an integer.", nil)
			return
		}
	}

	sleepGraphResponse, err := h.sleepUseCase.GetSleepGraphData(r.Context(), userID, days)
	if err != nil {
		logger.Log.WithField("user_id", userID).WithField("days", days).WithError(err).Error("Failed to get user sleep graph data")
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to get user sleep graph data", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, sleepGraphResponse)
}
