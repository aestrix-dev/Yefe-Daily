package handlers

import (
	"net/http"
	"yefe_app/v1/internal/usecase"
	"yefe_app/v1/pkg/logger"
	"yefe_app/v1/pkg/utils"

	"github.com/go-chi/chi/v5"
)

type DashboardHandler struct {
	usecase usecase.DashboardUsecase
}

func NewDashboardHandler(usecase usecase.DashboardUsecase) *DashboardHandler {
	return &DashboardHandler{usecase: usecase}
}

func (h DashboardHandler) Handle() *chi.Mux{
  router :=  chi.NewRouter()
  router.Get("/", h.GetDashboard)
  return router
}

func (h *DashboardHandler) GetDashboard(w http.ResponseWriter, r *http.Request) {

	data, err := h.usecase.GetDashboardData(r.Context())
	if err != nil {
		logger.Log.WithError(err).Error("failed to load dashboard")
		utils.ErrorResponse(w, http.StatusInternalServerError, "faild to laod dashboard", map[string]string{
			"error": "Failed to load dashboard",
		})
		return
	}

	utils.SuccessResponse(w, http.StatusOK, "Dashboard Data", data)
}
