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

type challengesHandler struct {
	challengeUseCase domain.ChallengeUseCase
}

func NewChallengesHandler(challengeUseCase domain.ChallengeUseCase) *challengesHandler {
	return &challengesHandler{
		challengeUseCase: challengeUseCase,
	}
}

// SetupRoutes configures all challenge-related routes
func (h *challengesHandler) Handle() *chi.Mux {
	router := chi.NewRouter()
	router.Get("/today", h.getTodaysChallenges)
	router.Get("/history", h.getChallengeHistory)
	router.Put("/{challengeID}/complete", h.completeChallenge)
	router.Get("/dashboard", h.getDashboard)
	router.Get("/stats", h.getUserStats)
	router.Get("/leaderboard", h.getLeaderboard)
	router.Get("/range", h.getChallengeHistory)
	return router
}

// getTodaysChallenges gets today's challenges for the authenticated user
func (h *challengesHandler) getTodaysChallenges(w http.ResponseWriter, r *http.Request) {
	var userChallngeDto dto.UserChallengeDTO
	var challengedto dto.ChallengeDTO
	userID := getUserIDFromContext(r.Context())

	userChallenge, err := h.challengeUseCase.GetUserChallengeForToday(userID)

	if err != nil {
		logger.Log.WithError(err).Error("Failed to get challange")
		http.Error(w, "Failed to get today's challenges", http.StatusInternalServerError)
		return
	}

	err = utils.TypeConverter(userChallenge, &userChallngeDto)

	if err != nil {
		logger.Log.WithError(err).Error("Failed to get challange")
		http.Error(w, "Failed to get today's challenges", http.StatusInternalServerError)
		return
	}

	challenge, err := h.challengeUseCase.GetChallengeByID(userChallenge.ChallengeID)

	if err != nil {
		logger.Log.WithError(err).Error("Failed to get challange")
		http.Error(w, "Failed to get challenge", http.StatusInternalServerError)
		return
	}

	err = utils.TypeConverter(challenge, &challengedto)

	if err != nil {
		logger.Log.WithError(err).Error("Failed to get challange")
		http.Error(w, "Failed to get today's challenges", http.StatusInternalServerError)
		return
	}
	userChallngeDto.Challenge = challengedto
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"challenge": userChallngeDto,
	})
}

// getChallengeHistory gets user's challenge history
func (h *challengesHandler) getChallengeHistory(w http.ResponseWriter, r *http.Request) {
	var dto []dto.UserChallengeDTO
	userID := getUserIDFromContext(r.Context())

	limitStr := r.URL.Query().Get("limit")
	limit := 10 // default
	if limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil {
			limit = l
		}
	}

	challenges, err := h.challengeUseCase.GetUserChallengeHistory(userID, limit)
	if err != nil {
		http.Error(w, "Failed to get challenge history", http.StatusInternalServerError)
		return
	}
	err = utils.TypeConverter(challenges, &dto)

	if err != nil {
		http.Error(w, "Failed to get today's challenges", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"challenge": dto,
	})
}

// completeChallenge marks a challenge as completed
func (h *challengesHandler) completeChallenge(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())
	challengeID := chi.URLParam(r, "challengeID")

	err := h.challengeUseCase.CompleteChallenge(userID, challengeID)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to complete challenge")
		http.Error(w, "Failed to complete challenge", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"message": "Challenge completed successfully",
		"status":  "completed",
	})
}

// getDashboard gets user's dashboard data
func (h *challengesHandler) getDashboard(w http.ResponseWriter, r *http.Request) {
	var todayChallengedto dto.ChallengeResponse
	var challengedto dto.ChallengeDTO
	var recentlyCompletedto []dto.ChallengeResponse
	var statsdto dto.ChallengeStatsDTO

	userID := getUserIDFromContext(r.Context())

	// Get today's challenges
	todaysChallenge, err := h.challengeUseCase.GetUserChallengeForToday(userID)
	if err != nil {
		logger.Log.WithError(err).Error("")
		http.Error(w, "Failed to get dashboard data", http.StatusInternalServerError)
		return
	}

	// Get recent completed challenges
	recentCompleted, err := h.challengeUseCase.GetUserChallengeHistory(userID, 5)
	if err != nil {
		logger.Log.WithError(err).Error("")
		http.Error(w, "Failed to get recent completed challenges", http.StatusInternalServerError)
		return
	}

	// Get user stats
	stats, err := h.challengeUseCase.GetUserStats(userID)
	if err != nil {
		logger.Log.WithError(err).Error("")
		http.Error(w, "Failed to get user stats", http.StatusInternalServerError)
		return
	}

	// Filter recent completed to only show completed ones
	for _, chg := range recentCompleted {
		_ = utils.TypeConverter(chg.Challenge, &challengedto)
		if chg.Status == dto.StatusCompleted {
			challenge := dto.ChallengeResponse{Challenge: &challengedto, IsCompleted: chg.Status == dto.StatusCompleted}
			recentlyCompletedto = append(recentlyCompletedto, challenge)
		}
	}
	err = utils.TypeConverter(todaysChallenge, &todayChallengedto)

	if err != nil {
		logger.Log.WithError(err).Error("")
		http.Error(w, "Failed to get today's challenges", http.StatusInternalServerError)
		return
	}

	err = utils.TypeConverter(stats, &statsdto)

	if err != nil {
		logger.Log.WithError(err).Error("")
		http.Error(w, "Failed to get user stats", http.StatusInternalServerError)
		return
	}

	if statsdto.CurrentStreak >= 7 {
		statsdto.SevendaysProgress = statsdto.CurrentStreak
	} else {
		statsdto.SevendaysProgress = statsdto.CurrentStreak % 7
	}
	statsdto.NoOfBadges = int(stats.TotalChallenges / 5)
	dashboard := &dto.DashboardResponse{
		TodaysChallenges:  todayChallengedto,
		RecentlyCompleted: recentlyCompletedto,
		Stats:             statsdto,
		CurrentStreak:     stats.CurrentStreak,
		TotalPoints:       stats.TotalPoints,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(dashboard)
}

// getUserStats gets user's statistics
func (h *challengesHandler) getUserStats(w http.ResponseWriter, r *http.Request) {
	var statsdto dto.ChallengeStatsDTO
	userID := getUserIDFromContext(r.Context())

	stats, err := h.challengeUseCase.GetUserStats(userID)

	err = utils.TypeConverter(stats, &statsdto)

	if err != nil {
		logger.Log.WithError(err).Error("")
		http.Error(w, "Failed to get user stats", http.StatusInternalServerError)
		return
	}
	if err != nil {
		http.Error(w, "Failed to get user stats", http.StatusInternalServerError)
		return
	}

	if statsdto.CurrentStreak >= 7 {
		statsdto.SevendaysProgress = statsdto.CurrentStreak
	} else {
		statsdto.SevendaysProgress = statsdto.CurrentStreak % 7
	}

	statsdto.NoOfBadges = int(stats.TotalChallenges / 5)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(statsdto)
}

// getLeaderboard gets the leaderboard
func (h *challengesHandler) getLeaderboard(w http.ResponseWriter, r *http.Request) {
	limitStr := r.URL.Query().Get("limit")
	limit := 10 // default
	if limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil {
			limit = l
		}
	}

	leaderboard, err := h.challengeUseCase.GetLeaderboard(limit)
	if err != nil {
		http.Error(w, "Failed to get leaderboard", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"leaderboard": leaderboard,
	})
}
