package handlers

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/logger"
	"yefe_app/v1/pkg/utils"

	"github.com/go-playground/validator"
)

type AuthHandler struct {
	authUseCase domain.AuthUseCase
	userRepo    domain.UserRepository
	validator   *validator.Validate
}

func (h *AuthHandler) Me(w http.ResponseWriter, r *http.Request) {
	var dtoUser dto.User
	user := getUserFromContext(r.Context())

	err := utils.TypeConverter(user, &dtoUser)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to get user")
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to get users", nil)
		return
	}

	utils.SuccessResponse(w, http.StatusOK, "user", user)
}

// Login handles user login
func (a AuthHandler) LoginRoute(w http.ResponseWriter, r *http.Request) {
	var req dto.LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		logger.Log.WithError(err).Error("")
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	// Set IP and User Agent
	req.IPAddress = utils.GetClientIP(r)
	req.UserAgent = r.UserAgent()

	// Validate request
	if err := a.validator.Struct(&req); err != nil {
		logger.Log.WithError(err).Error("")
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	user, err := a.authUseCase.Login(r.Context(), req)
	if err != nil {
		utils.HandleDomainError(w, err)
		return
	}
	utils.SuccessResponse(w, http.StatusCreated, "User logined-in successfully", user)
}

// Logout Handles user logout request
func (a AuthHandler) LogoutRoute(w http.ResponseWriter, r *http.Request) {
	sessionId := r.Context().Value("session_id").(string)
	req := dto.LogoutRequest{SessionID: sessionId}

	// Set IP and User Agent
	req.IPAddress = utils.GetClientIP(r)
	req.UserAgent = r.UserAgent()

	// Validate request
	if err := a.validator.Struct(&req); err != nil {
		logger.Log.WithError(err).Error("")
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", nil)
		return
	}

	err := a.authUseCase.Logout(r.Context(), req)
	if err != nil {
		utils.HandleDomainError(w, err)
		return
	}
	utils.SuccessResponse(w, http.StatusCreated, "User loggedout", nil)
}

// Register handles user registration
func (a AuthHandler) RegisterRoute(w http.ResponseWriter, r *http.Request) {
	var req dto.RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		logger.Log.WithError(err).Error("")
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", nil)
		return
	}

	// Set IP and User Agent
	req.IPAddress = utils.GetClientIP(r)
	req.UserAgent = r.UserAgent()

	// Validate request
	if err := a.validator.Struct(&req); err != nil {
		logger.Log.WithError(err).Error("")
		if strings.Contains(err.Error(), "Key: 'RegisterRequest.ConfirmPassword'") {
			utils.ErrorResponse(w, http.StatusBadRequest, "Passwords do not match", err)
			return
		}
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	user, err := a.authUseCase.Register(r.Context(), req)
	if userExists := errors.Is(err, domain.ErrEmailAlreadyExists); userExists {
		user, err = a.userRepo.GetByEmail(r.Context(), req.Email)
	}

	if err != nil {
		utils.HandleDomainError(w, err)
		return
	}

	token, err := a.authUseCase.Login(r.Context(), dto.LoginRequest{
		Email:     req.Email,
		Password:  req.Password,
		IPAddress: req.IPAddress,
		UserAgent: req.UserAgent,
	})
	if err != nil {
		logger.Log.WithError(err).Error("Could not log user in after reg")
		utils.ErrorResponse(w, http.StatusBadRequest, "Could not log user in", err)
		return
	}
	utils.SuccessResponse(w, http.StatusCreated, "User registered successfully", map[string]any{
		"user":  user,
		"token": token,
	})
}

func (a AuthHandler) AcceptNotifications(w http.ResponseWriter, r *http.Request) {
	user := getUserFromContext(r.Context())
	var req dto.AcceptNotificationRequest

	if user.Role == "admin" {
		utils.ErrorResponse(w, http.StatusForbidden, "Not open to admin user", nil)
		return
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		logger.Log.WithError(err).Error("")
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", nil)
		return
	}
	if err := a.validator.Struct(&req); err != nil {
		logger.Log.WithError(err).Error("")
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", nil)
		return
	}

	err := a.authUseCase.AcceptNotificaions(r.Context(), req.FcmToken, user)

	if err != nil {
		logger.Log.WithError(err).Error("Could not register notification")
		utils.ErrorResponse(w, http.StatusInternalServerError, "Could not register notification", nil)
		return
	}
	utils.SuccessResponse(w, http.StatusCreated, "User notifiaction created", nil)
}

func NewAuthHandler(authUseCase domain.AuthUseCase, userRepo domain.UserRepository) *AuthHandler {
	router := &AuthHandler{
		authUseCase: authUseCase,
		userRepo:    userRepo,
		validator:   validator.New(),
	}
	return router
}
