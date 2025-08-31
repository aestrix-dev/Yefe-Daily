package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"path"
	"syscall"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/infrastructure"
	"yefe_app/v1/internal/repository"
	"yefe_app/v1/internal/usecase"
	"yefe_app/v1/pkg/cache"
	"yefe_app/v1/pkg/logger"
	service "yefe_app/v1/pkg/services"
	"yefe_app/v1/pkg/services/fire_base"
	"yefe_app/v1/pkg/utils"

	"github.com/stripe/stripe-go/v74"
)

func main() {
	logger.Init()

	basePath, _ := utils.GetBasePath()
	pathToPuzzles := path.Join(basePath, "extras", "puzzles.json")
	pathToChallenges := path.Join(basePath, "extras", "challenges.json")
	pathToSongs := path.Join(basePath, "extras", "mood_music_catalog.json")
	pathToReflections := path.Join(basePath, "extras", "daily_reflection.json")
	firebasedb := path.Join(basePath, "extras", "firebase.db")

	// Load configuration
	config, err := utils.LoadConfig()
	if err != nil {
		logger.Log.WithError(err).Fatal("Failed to load config")
		return
	}
	stripe.Key = config.StripeConfig.SecretKey
	paymentConfig := config.StripeConfig

	fmcConfig := fire_base.FCMServiceConfig{
		Config:                 config.FirebaseConfig,
		DatabasePath:           firebasedb,
		NotificationWorkerName: "daily-notifications-worker",
	}

	serverCtx, serverStopCtx := context.WithCancel(context.Background())
	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGHUP, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT)

	inmemeoryCache := cache.NewCache(cache.CacheOptions{
		MaxSize:         500,
		DefaultTTL:      24 * time.Hour,
		CleanupInterval: 24 * time.Hour,
		EnableStats:     true,
	})

	_ = service.NewServiceManager()
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

	sessionRepo, err := repository.NewRedisSessionRepository(config.Persistence.Redis)
	if err != nil {
		logger.Log.WithError(err).Fatal("Failed to initialize redis")
		return
	}
	// Initialize DB
	db, err := infrastructure.NewDB(config.Persistence.PostgresSQl)
	if err != nil {
		logger.Log.WithError(err).Fatal("Failed to initialize database")
		return
	}
	logger.Log.Info("Database initialized")

	secEventRepo := repository.NewPostgresSecurityEventRepository(db)

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
	dailyRelectionUsecase, err := usecase.NewDailyReflectionUseCase(pathToReflections, inmemeoryCache)
	if err != nil {
		logger.Log.WithError(err).Fatal("Failed to load reflections")
		return
	}
	userChallengeRepo := repository.NewUserChallengeRepository(db)
	statsRepo := repository.NewChallengeStatsRepository(db)
	songRepo, err := repository.NewJSONMusicRepository(pathToSongs)

	if err != nil {
		logger.Log.WithError(err).Fatal("Failed to load songs")
		return

	}
	paymentRepo := repository.NewPaymentRepository(db)
	sleepRepo := repository.NewSleepRepository(db)

	dailyChallenge := inmemeoryCache.GetOrSetWithTTLAndContext(serverCtx, "daily-challenge", func() any {
		var dchallange domain.Challenge
		dchallange, err := challengeRepo.GetTodaysChallenge()
		if err != nil {
			challenge := challengeRepo.GetRandomChallange()
			err = challengeRepo.CreateChallenge(&challenge)
			if err != nil {
				logger.Log.WithError(err).Error("Could not generate daily challenge")
				return err
			}
			dchallange = challenge
		}
		return dchallange
	}, 24*time.Hour)

	logger.Log.WithFields(map[string]any{
		"ID":   dailyChallenge.(domain.Challenge).ID,
		"date": time.Now().String(),
	}).Debug("Created new daily challenge")

	err = scheduler.AddJob("set-daily-challenge", "Daily challenge", utils.DAILY, func(ctx context.Context) error {
		dailyChallenge := inmemeoryCache.GetOrSetWithTTLAndContext(serverCtx, "daily-challenge", func() any {
			challenge := challengeRepo.GetRandomChallange()
			if err != nil {
				logger.Log.WithError(err).Error("Could not generate daily challenge")
				return err
			}
			
			err = challengeRepo.CreateChallenge(&challenge)
			if err != nil {
				logger.Log.WithError(err).Error("Could not generate daily challenge")
				return err
			}
      logger.Log.Infof("New challenge created ID: %s, name: %s", challenge.ID, challenge.Title)
			return challenge
		}, 24*time.Hour)

		logger.Log.WithFields(map[string]any{
			"ID":   dailyChallenge.(domain.Challenge).ID,
			"date": time.Now().String(),
		}).Debug("Created new daily challenge")
		return nil
	})

	reflection := inmemeoryCache.GetOrSetWithTTLAndContext(serverCtx, "daily-reflection", func() any {
		ref := dailyRelectionUsecase.GetRandomDailyReflection()
		if err != nil {
			logger.Log.WithError(err).Error("Could not generate daily refletion")
			return err
		}
		return ref
	}, 24*time.Hour)

	logger.Log.WithFields(map[string]any{
		"ID":   reflection.(domain.DailyReflection).ID,
		"date": time.Now().String(),
	}).Debug("Created new daily reflection")

	err = scheduler.AddJob("set-daily-reflection", "Daily reflection", utils.DAILY, func(ctx context.Context) error {
		reflection := inmemeoryCache.GetOrSetWithTTLAndContext(serverCtx, "daily-reflection", func() any {
			ref := dailyRelectionUsecase.GetRandomDailyReflection()
			if err != nil {
				logger.Log.WithError(err).Error("Could not generate daily refletion")
				return err
			}
			return ref
		}, 24*time.Hour)

		logger.Log.WithFields(map[string]any{
			"ID":   reflection.(domain.DailyReflection).ID,
			"date": time.Now().String(),
		}).Debug("Created new daily reflection")
		return nil
	})

	serverConfig := infrastructure.ServerConfig{
		DB:                     db,
		AllowedHosts:           config.Server.AllowedHosts,
		JWT_SECRET:             config.Server.Secret,
		EmailService:           emailService,
		PaymentConfig:          paymentConfig,
		InviteURL:              config.Server.InviteURL,
		UserRepo:               userRepo,
		SessionRepo:            sessionRepo,
		SecEventRepo:           secEventRepo,
		JournalRepo:            journalRepo,
		UserPuzzleRepo:         userPuzzledRepo,
		PuzzleRepo:             puzzleRepo,
		ChallengeRepo:          challengeRepo,
		UserChallengeRepo:      userChallengeRepo,
		StatsRepo:              statsRepo,
		AdminRepo:              adminRepo,
		SongRepo:               songRepo,
		PaymentRepo:            paymentRepo,
		DailyReflectionUsecase: dailyRelectionUsecase,
		SleepRepo:              sleepRepo,
	}

	fcmService, err := fire_base.NewFCMNotificationService(serverCtx, db, serverStopCtx, fmcConfig, serverConfig.AdminUserUsecase(), scheduler)
	if err != nil {
		logger.Log.Fatal("Failed to create FCM notification service:", err)
	}

	serverConfig.FMCService = fcmService

	// Start the service (this will start background workers and scheduler)
	if err := fcmService.Start(); err != nil {
		log.Fatal("Failed to start FCM notification service:", err)
	}

	createSuperAdmin(serverCtx, userRepo, config.Server.SuperAdminEmail, config.Server.SuperAdminPassword)

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

func createSuperAdmin(ctx context.Context, repo domain.UserRepository, email string, adminPassword string) {
	salt := utils.GenerateSalt(utils.DefaultPasswordConfig.SaltLength)
	password_hash := utils.HashPassword(adminPassword, salt, utils.DefaultPasswordConfig)
	newUser := &domain.User{
		ID:           utils.GenerateID(),
		Email:        email,
		Role:         "admin",
		PasswordHash: password_hash,
		Salt:         salt,
	}

	err := repo.CreateAdminUser(ctx, newUser, "admin")
	if err != nil {
		logger.Log.Debug("Super admin already exists")
		return
	}
	logger.Log.Info("Created superadmin account")
}
