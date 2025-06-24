package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/logger"
	"yefe_app/v1/pkg/utils"

	"github.com/go-playground/validator/v10"
)

type AuthHandler struct {
	authUseCase domain.AuthUseCase
	validator   *validator.Validate
}

// Login handles user login
func (a AuthHandler) LoginRoute(w http.ResponseWriter, r *http.Request) {
	var req dto.LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		logger.Log.WithError(err).Error("")
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	// Set IP and User Agent
	req.IPAddress = utils.GetClientIP(r)
	req.UserAgent = r.UserAgent()

	// Validate request
	if err := a.validator.Struct(&req); err != nil {
		logger.Log.WithError(err).Error("")
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", err.Error())
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
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", err.Error())
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
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	// Set IP and User Agent
	req.IPAddress = utils.GetClientIP(r)
	req.UserAgent = r.UserAgent()

	// Validate request
	if err := a.validator.Struct(&req); err != nil {
		logger.Log.WithError(err).Error("")
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	user, err := a.authUseCase.Register(r.Context(), req)
	if err != nil {
		utils.HandleDomainError(w, err)
		return
	}
	utils.SuccessResponse(w, http.StatusCreated, "User registered successfully", map[string]any{
		"user":    user,
		"message": "Please check your email to verify your account",
	})
}

func NewAuthHandler(authUseCase domain.AuthUseCase) *AuthHandler {
	router := &AuthHandler{
		authUseCase: authUseCase,
		validator:   validator.New(),
	}
	return router
}
