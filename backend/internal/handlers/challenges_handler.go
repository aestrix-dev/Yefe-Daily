package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"

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
	router.Post("/{challengeID}/complete", h.completeChallenge)
	router.Get("/dashboard", h.getDashboard)
	router.Get("/stats", h.getUserStats)
	router.Get("/progress", h.getUserProgress)
	router.Get("/leaderboard", h.getLeaderboard)
	router.Get("/range", h.getChallengeHistory)
	return router
}

// getTodaysChallenges gets today's challenges for the authenticated user
func (h *challengesHandler) getTodaysChallenges(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())

	challenges, err := h.challengeUseCase.GetUserChallengesForToday(userID)
	if err != nil {
		http.Error(w, "Failed to get today's challenges", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"challenges": convertUserChallengesToDTO(challenges),
	})
}

// getChallengeHistory gets user's challenge history
func (h *challengesHandler) getChallengeHistory(w http.ResponseWriter, r *http.Request) {
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

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"challenges": convertUserChallengesToDTO(challenges),
	})
}

// completeChallenge marks a challenge as completed
func (h *challengesHandler) completeChallenge(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())
	challengeID := chi.URLParam(r, "challengeID")

	err := h.challengeUseCase.CompleteChallenge(userID, challengeID)
	if err != nil {
		http.Error(w, "Failed to complete challenge", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"message": "Challenge completed successfully",
		"status":  "completed",
	})
}

// getDashboard gets user's dashboard data
func (h *challengesHandler) getDashboard(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())

	// Get today's challenges
	todaysChallenges, err := h.challengeUseCase.GetUserChallengesForToday(userID)
	if err != nil {
		http.Error(w, "Failed to get dashboard data", http.StatusInternalServerError)
		return
	}

	// Get recent completed challenges
	recentCompleted, err := h.challengeUseCase.GetUserChallengeHistory(userID, 5)
	if err != nil {
		http.Error(w, "Failed to get recent completed challenges", http.StatusInternalServerError)
		return
	}

	// Get user stats
	stats, err := h.challengeUseCase.GetUserStats(userID)
	if err != nil {
		http.Error(w, "Failed to get user stats", http.StatusInternalServerError)
		return
	}

	// Filter recent completed to only show completed ones
	var completed []domain.UserChallenge
	for _, challenge := range recentCompleted {
		if challenge.Status == dto.StatusCompleted {
			completed = append(completed, challenge)
		}
	}

	dashboard := &dto.DashboardResponse{
		TodaysChallenges:  convertToChallengeResponses(todaysChallenges),
		RecentlyCompleted: convertToChallengeResponses(completed),
		Stats:             convertChallengeStatsToDTO(stats),
		CurrentStreak:     stats.CurrentStreak,
		TotalPoints:       stats.TotalPoints,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(dashboard)
}

// getUserStats gets user's statistics
func (h *challengesHandler) getUserStats(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())

	stats, err := h.challengeUseCase.GetUserStats(userID)
	if err != nil {
		http.Error(w, "Failed to get user stats", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(convertChallengeStatsToDTO(stats))
}

// getUserProgress gets user's progress for a specific period
func (h *challengesHandler) getUserProgress(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())
	period := r.URL.Query().Get("period")

	if period == "" {
		period = "weekly" // default
	}

	progress, err := h.challengeUseCase.GetUserProgress(userID, period)
	if err != nil {
		http.Error(w, "Failed to get user progress", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"progress": progress,
		"period":   period,
	})
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
	json.NewEncoder(w).Encode(map[string]interface{}{
		"leaderboard": convertChallengeStatsSliceToDTO(leaderboard),
	})
}

// Helper function to convert UserChallenge to ChallengeResponse
func convertToChallengeResponses(userChallenges []domain.UserChallenge) []*dto.ChallengeResponse {
	var responses []*dto.ChallengeResponse
	for _, uc := range userChallenges {
		response := &dto.ChallengeResponse{
			UserChallenge: convertUserChallengeToDTO(uc),
			IsCompleted:   uc.Status == dto.StatusCompleted,
			CanComplete:   uc.Status == dto.StatusPending,
		}
		responses = append(responses, response)
	}
	return responses
}

// Conversion functions from domain to DTOs
func convertChallengeToDTO(challenge domain.Challenge) *dto.ChallengeDTO {

	return &dto.ChallengeDTO{
		ID:          challenge.ID,
		Title:       challenge.Title,
		Description: challenge.Description,
		Type:        challenge.Type,
		Points:      challenge.Points,
		Date:        challenge.Date,
		CreatedAt:   challenge.CreatedAt,
		UpdatedAt:   challenge.UpdatedAt,
	}
}

func convertChallengesToDTO(challenges []domain.Challenge) []*dto.ChallengeDTO {
	var dtos []*dto.ChallengeDTO
	for _, challenge := range challenges {
		dtos = append(dtos, convertChallengeToDTO(challenge))
	}
	return dtos
}

func convertUserChallengeToDTO(userChallenge domain.UserChallenge) *dto.UserChallengeDTO {

	return &dto.UserChallengeDTO{
		ID:          userChallenge.ID,
		UserID:      userChallenge.UserID,
		ChallengeID: userChallenge.ChallengeID,
		Status:      userChallenge.Status,
		CompletedAt: userChallenge.CompletedAt,
		CreatedAt:   userChallenge.CreatedAt,
		UpdatedAt:   userChallenge.UpdatedAt,
	}
}

func convertUserChallengesToDTO(userChallenges []domain.UserChallenge) []*dto.UserChallengeDTO {
	var dtos []*dto.UserChallengeDTO
	for _, uc := range userChallenges {
		dtos = append(dtos, convertUserChallengeToDTO(uc))
	}
	return dtos
}

func convertChallengeStatsToDTO(stats domain.ChallengeStats) *dto.ChallengeStatsDTO {

	return &dto.ChallengeStatsDTO{
		UserID:          stats.UserID,
		TotalChallenges: stats.TotalChallenges,
		CompletedCount:  stats.CompletedCount,
		TotalPoints:     stats.TotalPoints,
		CurrentStreak:   stats.CurrentStreak,
		LongestStreak:   stats.LongestStreak,
	}
}

func convertChallengeStatsSliceToDTO(statsSlice []domain.ChallengeStats) []*dto.ChallengeStatsDTO {
	var dtos []*dto.ChallengeStatsDTO
	for _, stats := range statsSlice {
		dtos = append(dtos, convertChallengeStatsToDTO(stats))
	}
	return dtos
}
