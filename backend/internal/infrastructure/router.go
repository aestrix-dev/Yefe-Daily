package infrastructure

import (
	"net/http"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers"
	middlewares "yefe_app/v1/internal/infrastructure/middleware"
	usecase "yefe_app/v1/internal/useCase"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"gorm.io/gorm"
)

type ServerConfig struct {
	DB           *gorm.DB
	JWT_SECRET   string
	UserRepo     domain.UserRepository
	SessionRepo  domain.SessionRepository
	SecEventRepo domain.SecurityEventRepository
}

func (conf ServerConfig) auth_usecase() domain.AuthUseCase {
	return usecase.NewAuthUseCase(conf.UserRepo, conf.SessionRepo, conf.SecEventRepo, conf.JWT_SECRET)
}

func (conf ServerConfig) auth_middleware() *middlewares.AuthMiddleware {
	return middlewares.NewAuthMiddleware(conf.JWT_SECRET, conf.SessionRepo, conf.UserRepo, conf.SecEventRepo)

}

func NewRouter(config ServerConfig) http.Handler {
	r := chi.NewRouter()
	r.Use(middleware.Logger)

	auth_handlers := handlers.NewAuthHandler(config.auth_usecase())
	r.Group(func(r chi.Router) {
		r.Use(config.auth_middleware().RequireAuth)
		r.Post("/auth/logout", auth_handlers.LogoutRoute)
	})

	// auth routes
	r.Post("/auth/login", auth_handlers.LoginRoute)
	r.Post("/auth/register", auth_handlers.RegisterRoute)

	return r
}
