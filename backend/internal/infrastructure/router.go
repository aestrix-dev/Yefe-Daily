package infrastructure

import (
	"net/http"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers"
	usecase "yefe_app/v1/internal/useCase"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"gorm.io/gorm"
)

type ServerConfig struct {
	DB           *gorm.DB
	UserRepo     domain.UserRepository
	SessionRepo  domain.SessionRepository
	SecEventRepo domain.SecurityEventRepository
}

func (conf *ServerConfig) auth_usecase() domain.AuthUseCase {
	return usecase.NewAuthUseCase(conf.UserRepo, conf.SessionRepo, conf.SecEventRepo, "")
}

func NewRouter(config ServerConfig) http.Handler {
	r := chi.NewRouter()
	r.Use(middleware.Logger)
	r.Mount("/auth", handlers.AuthHandler(config.auth_usecase()))
	return r
}
