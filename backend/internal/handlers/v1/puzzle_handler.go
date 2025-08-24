package handlers

import (
	"encoding/json"
	"net/http"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/logger"
	"yefe_app/v1/pkg/utils"

	"github.com/go-chi/chi/v5"
)

type puzzleHandler struct {
	puzzleUseCase domain.PuzzleUseCase
}

func NewPuzzleHandler(puzzleUsecase domain.PuzzleUseCase) *puzzleHandler {
	return &puzzleHandler{
		puzzleUseCase: puzzleUsecase,
	}
}

func (p *puzzleHandler) Handle() *chi.Mux {
	router := chi.NewRouter()
	router.Get("/daily", p.GetDailyPuzzle)
	router.Put("/submit", p.SubmitDailyPuzzleAnswer)
	router.Get("/stats", p.GetUserStats)
	router.Get("/completed", p.GetUserCompletedPuzzles)
	return router
}

func (h *puzzleHandler) GetDailyPuzzle(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())
	if userID == "" {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	dailyPuzzle, err := h.puzzleUseCase.GetRandomPuzzle()
	if err != nil {
		logger.Log.WithError(err).Error("Failed to get daily puzzle")
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to get daily puzzle", nil)
		return
	}

	utils.SuccessResponse(w, http.StatusOK, "", map[string]any{
		"data": dailyPuzzle,
	})
}

// SubmitDailyPuzzleAnswer submits answer for today's puzzle
func (h *puzzleHandler) SubmitDailyPuzzleAnswer(w http.ResponseWriter, r *http.Request) {
	//	today := time.Now().Format("2006-01-02")
	userID := getUserIDFromContext(r.Context())
	if userID == "" {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	//	_, err := h.puzzleUseCase.GetUserPuzzleProgressForDate(userID, today)
	//if err == nil {
	//utils.ErrorResponse(w, http.StatusBadRequest, "User already submitted", nil)
	//return
	//	}

	var req dto.SubmitAnswerRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		logger.Log.WithError(err).Error("failed to submit answer: invalid request body")
		utils.ErrorResponse(w, http.StatusBadRequest, "Failed to submit answer: invalid request body", nil)
		return
	}

	result, err := h.puzzleUseCase.SubmitPuzzleAnswer(userID, req.PuzzleId, req.SelectedAnswer)
	if err != nil {
    logger.Log.WithError(err).Error("failed to submit answer: Puzzle %s", req.PuzzleId)
		utils.ErrorResponse(w, 400, "Failed to submit answer", err.Error())
		return
	}

	utils.SuccessResponse(w, http.StatusOK, "", map[string]any{
		"data": result,
	})
}

// GetUserStats retrieves user's puzzle statistics
func (h *puzzleHandler) GetUserStats(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())
	if userID == "" {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	stats, err := h.puzzleUseCase.GetUserPuzzleStats(userID)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to get user stats")
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to get user stats", nil)
		return
	}
	utils.SuccessResponse(w, http.StatusOK, "", map[string]any{
		"data": stats,
	})
}

// GetUserCompletedPuzzles retrieves user's completed puzzles history
func (h *puzzleHandler) GetUserCompletedPuzzles(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())
	if userID == "" {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	completedPuzzles, err := h.puzzleUseCase.GetUserCompletedPuzzles(userID)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to get completed puzzles")
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to get completed puzzles", nil)
		return
	}

	utils.SuccessResponse(w, http.StatusOK, "", map[string]any{
		"data": completedPuzzles,
	})
}
