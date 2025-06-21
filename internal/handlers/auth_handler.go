package handlers

import (
	"encoding/json"
	"net/http"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
	usecase "yefe_app/v1/internal/useCase"

	"github.com/go-chi/chi/v5"
)

type authHandler struct {
	user_usecase domain.UserService
}

func (a authHandler) Handle() *chi.Mux {
	router := chi.NewRouter()
	return router
}

func (h *authHandler) Register(w http.ResponseWriter, r *http.Request) {
	var req dto.CreateUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid input", http.StatusBadRequest)
		return
	}

	if err := h.user_usecase.CreateUser(req); err != nil {
		http.Error(w, "Failed to register user", http.StatusInternalServerError)
		return
	}

	res := dto.UserResponse{
		ID:   user.ID,
		Name: user.Name,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(res)
}

func AuthHandler(uc usecase.UserUsecase) *chi.Mux {
	handler := authHandler{user_usecase: uc}
	return handler.Handle()
}
