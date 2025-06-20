package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
	"yefe_app/v1/internal/infrastructure"
	"yefe_app/v1/pkg/logger"
	"yefe_app/v1/pkg/utils"
)

func main() {
	config, err := utils.LoadConfig()
	if err != nil {

		logger.Log.WithError(err)
		return
	}
	logger.Init()

	logger.Log.WithFields(map[string]interface{}{
		"host": config.Server.Host,
		"port": config.Server.Port,
	}).Debug("Configuration loaded")

	// Initialize DB
	fmt.Println(config)
	_, err = infrastructure.NewDB(config.Persistence.PostgresSQl)
	if err != nil {
		logger.Log.WithError(err).Fatal("Failed to initialize database")
		return
	}

	logger.Log.Info("Database initialized")

	// Setup router and server
	router := infrastructure.NewRouter()
	address := fmt.Sprintf("%s:%d", config.Server.Host, config.Server.Port)
	server := &http.Server{Addr: address, Handler: router}

	logger.Log.WithField("address", address).Info("Starting server")

	// Setup graceful shutdown
	serverCtx, serverStopCtx := context.WithCancel(context.Background())
	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGHUP, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT)

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

	logger.Log.Info("Starting server")
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		logger.Log.WithError(err).Fatal("Server failed")
	}

	<-serverCtx.Done()
	logger.Log.Info("Server context closed. Exiting.")
}
