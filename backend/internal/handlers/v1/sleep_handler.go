package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/utils"
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
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request payload", nil)
		return
	}

	userID, ok := r.Context().Value("userID").(uint)
	if !ok {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	sleep, err := h.sleepUseCase.RecordSleep(r.Context(), userID, req.SleptAt, req.WokeUpAt)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to record sleep", nil)
		return
	}

	utils.JSONResponse(w, http.StatusCreated, sleep)
}

func (h *SleepHandler) getUserSleeps(w http.ResponseWriter, r *http.Request) {
	userID, ok := r.Context().Value("userID").(uint)
	if !ok {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	sleeps, err := h.sleepUseCase.GetUserSleeps(r.Context(), userID)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to get user sleeps", nil)
		return
	}

	utils.JSONResponse(w, http.StatusOK, sleeps)
}

func (h *SleepHandler) getSleepGraphData(w http.ResponseWriter, r *http.Request) {
	userID, ok := r.Context().Value("userID").(uint)
	if !ok {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	days := 7 // default to 7 days
	daysStr := r.URL.Query().Get("days")
	if daysStr != "" {
		days, _ = strconv.Atoi(daysStr)
	}

	sleeps, err := h.sleepUseCase.GetSleepGraphData(r.Context(), userID, days)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to get user sleep graph data", nil)
		return
	}

	graphData := make([]dto.SleepGraphData, 0, len(sleeps))
	for _, s := range sleeps {
		graphData = append(graphData, dto.SleepGraphData{
			Date:     s.CreatedAt,
			Duration: s.WokeUpAt.Sub(s.SleptAt).Hours(),
		})
	}

	utils.JSONResponse(w, http.StatusOK, graphData)
}
