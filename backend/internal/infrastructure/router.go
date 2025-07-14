package infrastructure

import (
	"net/http"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/v1"
	middlewares "yefe_app/v1/internal/infrastructure/middleware"
	usecase "yefe_app/v1/internal/useCase"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"gorm.io/gorm"
)

type ServerConfig struct {
	DB                *gorm.DB
	JWT_SECRET        string
	EmailService      domain.EmailService
	UserRepo          domain.UserRepository
	SessionRepo       domain.SessionRepository
	SecEventRepo      domain.SecurityEventRepository
	JournalRepo       domain.JournalRepository
	PuzzleRepo        domain.PuzzleRepository
	UserPuzzleRepo    domain.UserPuzzleRepository
	ChallengeRepo     domain.ChallengeRepository
	UserChallengeRepo domain.UserChallengeRepository
	StatsRepo         domain.ChallengeStatsRepository
	AdminRepo         domain.AdminUserRepository
	SongRepo          domain.SongRepository
	PaymentRepo       domain.PaymentRepository
}

func (conf ServerConfig) auth_usecase() domain.AuthUseCase {
	return usecase.NewAuthUseCase(conf.UserRepo, conf.SessionRepo, conf.SecEventRepo, conf.JWT_SECRET)
}

func (conf ServerConfig) admin_user_usecase() domain.AdminUserUseCase {
	return usecase.NewAdminUserUseCase(conf.AdminRepo, conf.UserRepo, conf.EmailService)
}

func (conf ServerConfig) payment_usercase() domain.PaymentUseCase {
	return usecase.NewPaymentUseCase(conf.PaymentRepo)
}

func (conf ServerConfig) journal_usecase() domain.JournalUseCase {
	return usecase.NewJournalUseCase(conf.JournalRepo, conf.UserRepo)
}

func (conf ServerConfig) puzzle_usecase() domain.PuzzleUseCase {
	return usecase.NewPuzzleUseCase(conf.PuzzleRepo, conf.UserPuzzleRepo)
}
func (conf ServerConfig) song_usecase() domain.SongUseCase {
	return usecase.NewMusicUseCase(conf.SongRepo)
}

func (conf ServerConfig) challenges_usecase() domain.ChallengeUseCase {
	return usecase.NewChallengeUseCase(conf.ChallengeRepo, conf.UserChallengeRepo, conf.StatsRepo)
}
func (conf ServerConfig) auth_middleware() *middlewares.AuthMiddleware {
	return middlewares.NewAuthMiddleware(conf.JWT_SECRET, conf.SessionRepo, conf.UserRepo, conf.SecEventRepo)
}

func NewRouter(config ServerConfig) http.Handler {

	auth_handlers := handlers.NewAuthHandler(config.auth_usecase())
	journal_handlers := handlers.NewJournalHandler(config.journal_usecase())
	puzzle_handler := handlers.NewPuzzleHandler(config.puzzle_usecase())
	challenges_handler := handlers.NewChallengesHandler(config.challenges_usecase())
	admin_user_handelrs := handlers.NewAdminUserHandler(config.admin_user_usecase())
	song_handler := handlers.NewMusicHandler(config.song_usecase())
	payments_handler := handlers.NewPaymentHandler(config.payment_usercase())

	r := chi.NewRouter()
	r.Use(middleware.Logger)
	r.Route("/v1", func(r chi.Router) {
		r.Group(func(r chi.Router) {
			r.Use(config.auth_middleware().RequireAuth)
			r.Post("/auth/logout", auth_handlers.LogoutRoute)
			r.Mount("/journal", journal_handlers.Handle())
			r.Mount("/puzzle", puzzle_handler.Handle())
			r.Mount("/challenges", challenges_handler.Handle())
			r.Mount("/songs", song_handler.Handle())
			r.Mount("/payments", payments_handler.Handle())
		})

		r.Group(func(r chi.Router) {
			r.Use(config.auth_middleware().RequireAuth)
			r.Use(config.auth_middleware().AdminOnly)
			r.Mount("/admin", admin_user_handelrs.Handle())
		})

		// auth routes
		r.Post("/auth/login", auth_handlers.LoginRoute)
		r.Post("/auth/register", auth_handlers.RegisterRoute)
		r.Post("/accept-invitation", admin_user_handelrs.AcceptInvitation)
	})

	return r
}
