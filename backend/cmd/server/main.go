package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"path"
	"syscall"
	"time"
	"yefe_app/v1/internal/infrastructure"
	"yefe_app/v1/internal/repository"
	"yefe_app/v1/pkg/cache"
	"yefe_app/v1/pkg/logger"
	service "yefe_app/v1/pkg/services"
	"yefe_app/v1/pkg/utils"

	"github.com/stripe/stripe-go/v74"
)

func main() {

	logger.Init()

	basePath, _ := utils.GetBasePath()
	pathToPuzzles := path.Join(basePath, "extras", "puzzles.json")
	pathToChallenges := path.Join(basePath, "extras", "challenges.json")
	pathToSongs := path.Join(basePath, "extras", "mood_music_catalog.json")

	// Load configuration
	config, err := utils.LoadConfig()
	if err != nil {
		logger.Log.WithError(err).Fatal("Failed to load config")
		return
	}
	stripe.Key = config.StripeConfig.SecretKey

	serverCtx, serverStopCtx := context.WithCancel(context.Background())
	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGHUP, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT)

	inmemeoryCache := cache.NewCache(cache.CacheOptions{
		MaxSize:         500,
		DefaultTTL:      24 * time.Hour,
		CleanupInterval: 24 * time.Hour,
		EnableStats:     true,
	})

	_ = service.NewServiceManager(nil)
	emailService := service.NewEmailService(config.EmailConfig, nil)
	if err := emailService.Start(); err != nil {
		logger.Log.WithError(err).Error("Failed to start email service")
		return
	}

	scheduler := service.NewScheduler(logger.Log, serverCtx, serverStopCtx)
	scheduler.Start()
	defer scheduler.Stop()

	// Init logger

	logger.Log.WithFields(map[string]any{
		"host": config.Server.Host,
		"port": config.Server.Port,
	}).Debug("Configuration loaded")

	// Initialize DB
	db, err := infrastructure.NewDB(config.Persistence.PostgresSQl)
	if err != nil {
		logger.Log.WithError(err).Fatal("Failed to initialize database")
		return
	}
	logger.Log.Info("Database initialized")

	secEventRepo := repository.NewPostgresSecurityEventRepository(db)
	sessionRepo, err := repository.NewRedisSessionRepository(config.Persistence.Redis)
	if err != nil {
		logger.Log.WithError(err).Fatal("Failed to initialize redis")
		return
	}
	userRepo := repository.NewUserRepository(db, secEventRepo)
	journalRepo := repository.NewJournalRepository(db)
	userPuzzledRepo := repository.NewUserPuzzleRepository(db)
	puzzleRepo := repository.NewPuzzleRepository(pathToPuzzles)
	adminRepo := repository.NewAdminUserRepository(db, userRepo)
	challengeRepo, err := repository.NewChallengeRepository(db, pathToChallenges)

	if err != nil {
		logger.Log.WithError(err).Fatal("Failed to load challenges")
		return
	}
	userChallengeRepo := repository.NewUserChallengeRepository(db)
	statsRepo := repository.NewChallengeStatsRepository(db)
	songRepo, err := repository.NewJSONMusicRepository(pathToSongs)

	if err != nil {
		logger.Log.WithError(err).Fatal("Failed to load songs")
		return

	}

	scheduler.AddJob("set-daily-puzzle", "Daily Puzzly", utils.DAILY, func(ctx context.Context) error {
		_, ok := inmemeoryCache.Get("daily-puzzle")
		if !ok {
			puzzle, err := puzzleRepo.GetRandomPuzzle()
			if err != nil {
				logger.Log.WithError(err).Error("Could not generate daily puzzle")
				return err
			}
			logger.Log.WithFields(map[string]any{
				"ID":   puzzle.ID,
				"date": time.Now().String(),
			}).Debug("Created new daily puzzle")
			inmemeoryCache.SetWithTTLAndContext(serverCtx, "daily-puzzle", puzzle, 24*time.Hour)
		}
		return nil
	})

	scheduler.AddJob("set-daily-challenges", "Daily Challenges", utils.DAILY, func(ctx context.Context) error {
		_, ok := inmemeoryCache.Get("daily-challenge")
		if !ok {
			challenge := challengeRepo.GetRandomChallange() // TODO this should also return an error
			logger.Log.WithFields(map[string]any{
				"ID":   challenge.ID,
				"date": time.Now().String(),
			}).Debug("Created new daily challenge")
			err := challengeRepo.CreateChallenge(&challenge)
			if err != nil {
				logger.Log.WithError(err).Error("Could not create challenge puzzle")
			}
			inmemeoryCache.SetWithTTLAndContext(serverCtx, "daily-challenge", challenge, 24*time.Hour)
		}
		return nil
	})

	serverConfig := infrastructure.ServerConfig{
		DB:                db,
		JWT_SECRET:        config.Server.Secret,
		UserRepo:          userRepo,
		SessionRepo:       sessionRepo,
		SecEventRepo:      secEventRepo,
		JournalRepo:       journalRepo,
		UserPuzzleRepo:    userPuzzledRepo,
		PuzzleRepo:        puzzleRepo,
		ChallengeRepo:     challengeRepo,
		UserChallengeRepo: userChallengeRepo,
		StatsRepo:         statsRepo,
		AdminRepo:         adminRepo,
		SongRepo:          songRepo,
		EmailService:      emailService,
	}

	// Setup router and server
	router := infrastructure.NewRouter(serverConfig)
	address := fmt.Sprintf("%s:%d", config.Server.Host, config.Server.Port)
	server := &http.Server{Addr: address, Handler: router}

	logger.Log.WithField("address", address).Info("Starting server")

	// Graceful shutdown setup

	go func() {
		<-sig
		logger.Log.Warn("Shutdown signal received")

		shutdownCtx, cancelCtx := context.WithTimeout(serverCtx, 30*time.Second)
		defer cancelCtx()

		go func() {
			<-shutdownCtx.Done()
			if shutdownCtx.Err() == context.DeadlineExceeded {
				logger.Log.Fatal("Graceful shutdown timed out... forcing exit.")
			}
		}()

		if err := server.Shutdown(shutdownCtx); err != nil {
			logger.Log.WithError(err).Fatal("Failed to gracefully shutdown server")
		}

		logger.Log.Info("Server shutdown completed")
		serverStopCtx()
	}()

	// Start the server
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		logger.Log.WithError(err).Fatal("Server failed")
	}

	<-serverCtx.Done()
	logger.Log.Info("Server context closed. Exiting.")
}

//TODO set daily puzzles and challenges on startup,
