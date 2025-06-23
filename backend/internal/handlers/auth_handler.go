package handlers

import (
	"encoding/json"
	"net/http"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/logger"
	"yefe_app/v1/pkg/utils"

	"github.com/go-chi/chi/v5"
	"github.com/go-playground/validator/v10"
)

type authHandler struct {
	authUseCase domain.AuthUseCase
	validator   *validator.Validate
}

func (a *authHandler) Handle() *chi.Mux {
	router := chi.NewRouter()
	router.Post("/register", a.RegisterRoute)
	router.Post("/login", a.LoginRoute)
	return router
}

// Login handles user login

func (a *authHandler) LoginRoute(w http.ResponseWriter, r *http.Request) {
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

// Register handles user registration
func (a *authHandler) RegisterRoute(w http.ResponseWriter, r *http.Request) {
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

func AuthHandler(authUseCase domain.AuthUseCase) *chi.Mux {
	router := &authHandler{
		authUseCase: authUseCase,
		validator:   validator.New(),
	}
	return router.Handle()
}
