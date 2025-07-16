package handlers

import (
	"net/http"
	"strconv"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/pkg/utils"

	"github.com/go-chi/chi/v5"
)

type userEventsHandler struct {
	uc domain.UserActivityUsecase
}

func NewUserEventsHandler(uc domain.UserActivityUsecase) userEventsHandler {
	return userEventsHandler{uc}
}

func (h userEventsHandler) Handle() *chi.Mux {
	router := chi.NewRouter()
	router.Get("/", h.getEvents)
	return router
}

func (h userEventsHandler) getEvents(w http.ResponseWriter, r *http.Request) {
	limit := 10
	if l := r.URL.Query().Get("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 {
			limit = parsed
		}
	}

	events, err := h.uc.GetRecentActivity(r.Context(), limit)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "could not get user events", nil)
		return
	}

	utils.SuccessResponse(w, http.StatusAccepted, "User events", events)

	return
}
