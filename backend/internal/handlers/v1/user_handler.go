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

type adminUserHandler struct {
	adminUC domain.AdminUserUseCase
}

func NewAdminUserHandler(adminUC domain.AdminUserUseCase) *adminUserHandler {
	return &adminUserHandler{adminUC: adminUC}
}

func (h *adminUserHandler) Handle() *chi.Mux {
	router := chi.NewRouter()
	router.Get("/users", h.listUsers)
	router.Get("/{userID}", h.getUser)
	router.Get("/admins", h.listAdminUsers)
	router.Put("/{userID}/status", h.updateUserStatus)
	router.Put("/{userID}/plan", h.updateUserPlan)
	router.Post("/invite", h.inviteNewAdmin)
	router.Get("/invitations", h.getPendingInvitations)
	router.Delete("/{userID}", h.deleteUser)
	return router
}

// @Summary Delete user
// @Description Delete a user account
// @Tags Admin
// @Param userID path string true "User ID"
// @Success 204
// @Failure 400 {object} web.ErrorResponse
// @Failure 404 {object} web.ErrorResponse
// @Failure 500 {object} web.ErrorResponse
// @Router /admin/users/{userID} [delete]
func (h *adminUserHandler) deleteUser(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userID")
	if userID == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid user ID", nil)
		return
	}

	if err := h.adminUC.DeleteUser(r.Context(), userID); err != nil {
		logger.Log.WithError(err).Error("Could not delete user")
		utils.HandleDomainError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// @Summary List users
// @Description Get paginated list of users with filters
// @Tags Admin
// @Param email query string false "Email filter"
// @Param status query string false "Status filter (active, suspended)"
// @Param plan query string false "Plan filter (free, yefe_plus)"
// @Param limit query int false "Results limit (default: 50)" default(50)
// @Param offset query int false "Results offset" default(0)
// @Success 200 {object} dto.UserListResponse
// @Failure 400 {object} web.ErrorResponse
// @Failure 500 {object} web.ErrorResponse
// @Router /admin/users [get]
func (h *adminUserHandler) listAdminUsers(w http.ResponseWriter, r *http.Request) {
	filter := dto.UserListFilter{
		Status: r.URL.Query().Get("status"),
		Role:   "admin",
	}

	// Parse pagination parameters with defaults
	limit, err := strconv.Atoi(r.URL.Query().Get("limit"))
	if err != nil || limit <= 0 {
		limit = 50
	}
	filter.Limit = limit

	offset, err := strconv.Atoi(r.URL.Query().Get("offset"))
	if err != nil || offset < 0 {
		offset = 0
	}
	filter.Offset = offset

	users, err := h.adminUC.GetAllUsers(r.Context(), filter)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to get users", nil)
		return
	}

	utils.SuccessResponse(w, http.StatusOK, "users", users)
}

// @Description Get user
func (h *adminUserHandler) getUser(w http.ResponseWriter, r *http.Request) {
	var dtoUser dto.User
	userID := chi.URLParam(r, "userID")

	user, err := h.adminUC.GetUserByID(r.Context(), userID)

	if err != nil {
		logger.Log.WithError(err).Error("Failed to get admin user")
		utils.ErrorResponse(w, http.StatusNotFound, "Failed to get user", nil)
		return
	}

	err = utils.TypeConverter(user, &dtoUser)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to get user")
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to get users", nil)
		return
	}

	utils.SuccessResponse(w, http.StatusOK, "user", user)
}

// @Summary List users
// @Description Get paginated list of users with filters
// @Tags Admin
// @Param email query string false "Email filter"
// @Param status query string false "Status filter (active, suspended)"
// @Param plan query string false "Plan filter (free, yefe_plus)"
// @Param limit query int false "Results limit (default: 50)" default(50)
// @Param offset query int false "Results offset" default(0)
// @Success 200 {object} dto.UserListResponse
// @Failure 400 {object} web.ErrorResponse
// @Failure 500 {object} web.ErrorResponse
// @Router /admin/users [get]
func (h *adminUserHandler) listUsers(w http.ResponseWriter, r *http.Request) {
	filter := dto.UserListFilter{
		Status: r.URL.Query().Get("status"),
		Plan:   r.URL.Query().Get("plan"),
		Role:   "user",
	}

	// Parse pagination parameters with defaults
	limit, err := strconv.Atoi(r.URL.Query().Get("limit"))
	if err != nil || limit <= 0 {
		limit = 50
	}
	filter.Limit = limit

	offset, err := strconv.Atoi(r.URL.Query().Get("offset"))
	if err != nil || offset < 0 {
		offset = 0
	}
	filter.Offset = offset

	users, err := h.adminUC.GetAllUsers(r.Context(), filter)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to get users")
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to get users", nil)
		return
	}

	utils.SuccessResponse(w, http.StatusOK, "users", users)
}

// @Summary Update user status
// @Description Update user account status
// @Tags Admin
// @Param userID path string true "User ID"
// @Param request body dto.UpdateStatusRequest true "Status update"
// @Success 204
// @Failure 400 {object} web.ErrorResponse
// @Failure 404 {object} web.ErrorResponse
// @Failure 500 {object} web.ErrorResponse
// @Router /admin/users/{userID}/status [patch]
func (h *adminUserHandler) updateUserStatus(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userID")
	if userID == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid user ID", nil)
		return
	}

	var req dto.UpdateStatusRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", nil)
		return
	}

	if err := h.adminUC.UpdateUserStatus(r.Context(), userID, req.Status); err != nil {
		logger.Log.WithError(err).Error("Could not update user")
		utils.HandleDomainError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// @Summary Update user plan
// @Description Update user subscription plan
// @Tags Admin
// @Param userID path string true "User ID"
// @Param request body dto.UpdatePlanRequest true "Plan update"
// @Success 204
// @Failure 400 {object} web.ErrorResponse
// @Failure 404 {object} web.ErrorResponse
// @Failure 500 {object} web.ErrorResponse
// @Router /admin/users/{userID}/plan [patch]
func (h *adminUserHandler) updateUserPlan(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userID")
	if userID == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid user ID", nil)
		return
	}

	var req dto.UpdatePlanRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", nil)
		return
	}

	if err := h.adminUC.UpdateUserPlan(r.Context(), userID, req.Plan); err != nil {
		logger.Log.WithError(err).Error("Failed to update user plan")
		utils.HandleDomainError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// @Summary Invite new admin
// @Description Send invitation to a new admin user
// @Tags Admin
// @Param request body dto.AdminInvitationRequest true "Invitation details"
// @Success 201
// @Failure 400 {object} web.ErrorResponse
// @Failure 500 {object} web.ErrorResponse
// @Router /admin/invitations [post]
func (h *adminUserHandler) inviteNewAdmin(w http.ResponseWriter, r *http.Request) {
	var req dto.AdminInvitationEmailRequest
	userID := getUserIDFromContext(r.Context())

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", nil)
		return
	}

	if err := h.adminUC.InviteNewAdmin(r.Context(), req, userID); err != nil {
		logger.Log.WithError(err).Error("Failed to send invite")
		utils.HandleDomainError(w, err)
		return
	}

	w.WriteHeader(http.StatusCreated)
}

// @Summary Get pending invitations
// @Description Get list of pending admin invitations
// @Tags Admin
// @Success 200 {array} dto.AdminInvitation
// @Failure 500 {object} web.ErrorResponse
// @Router /admin/invitations [get]
func (h *adminUserHandler) getPendingInvitations(w http.ResponseWriter, r *http.Request) {
	invitations, err := h.adminUC.GetPendingInvitations(r.Context())
	if err != nil {
		logger.Log.WithError(err).Error("Failed to get pending invites")
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to get pending invitations", nil)
		return
	}

	utils.SuccessResponse(w, http.StatusOK, "invitations", invitations)
}

// @Summary Accept invitation
// @Description Accept admin invitation and complete registration
// @Tags Admin
// @Success 200
// @Failure 400 {object} web.ErrorResponse
// @Failure 404 {object} web.ErrorResponse
// @Failure 500 {object} web.ErrorResponse
// @Router /admin/invitations/accept [post]
func (h *adminUserHandler) AcceptInvitation(w http.ResponseWriter, r *http.Request) {
	var req dto.AcceptInviteDTO
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", nil)
		return
	}

	if req.ConfirmPassword != req.Password {
		utils.ErrorResponse(w, http.StatusBadRequest, "Passwords do not match", nil)
		return
	}

	if err := h.adminUC.AcceptInvitation(r.Context(), req); err != nil {
		utils.HandleDomainError(w, err)
		return
	}

	w.WriteHeader(http.StatusOK)
}
