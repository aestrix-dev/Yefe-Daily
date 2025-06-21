package infrastructure

import (
	"net/http"
	"yefe_app/v1/internal/handlers"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

func NewRouter() http.Handler {
	r := chi.NewRouter()
	r.Use(middleware.Logger)
	r.Mount("/auth", handlers.AuthHandler())
	return r
}
