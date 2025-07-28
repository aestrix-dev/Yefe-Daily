package handlers

import (
	"encoding/json"
	"net/http"
	"yefe_app/v1/internal/domain"
)

type dailyreflectionhandler struct {
	dailyreflectionUseCase domain.DailyReflectionUseCase
}

func NewDailyreflectionHandler(dailyreflectionUseCase domain.DailyReflectionUseCase) *dailyreflectionhandler {
	return &dailyreflectionhandler{
		dailyreflectionUseCase: dailyreflectionUseCase,
	}
}

// getTodaysChallenges gets today's challenges for the authenticated user
func (h *dailyreflectionhandler) GetTodaysReflection(w http.ResponseWriter, r *http.Request) {
	reflection, err := h.dailyreflectionUseCase.GetTodaysDailyReflection(r.Context())

	if err != nil {
		http.Error(w, "Failed to get today's challenges", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"reflection": reflection,
	})
}
