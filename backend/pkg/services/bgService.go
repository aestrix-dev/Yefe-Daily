package service

import (
	"context"
	"errors"
	"fmt"
	"log"
	"os"
	"os/signal"
	"runtime"
	"sync"
	"syscall"
	"time"
	"yefe_app/v1/pkg/logger"
)

// Service states
const (
	ServiceStateStopped = iota
	ServiceStateStarting
	ServiceStateRunning
	ServiceStateStopping
	ServiceStateError
)

// Common errors
var (
	ErrServiceAlreadyRunning = errors.New("service is already running")
	ErrServiceNotRunning     = errors.New("service is not running")
	ErrServiceStopped        = errors.New("service has been stopped")
	ErrServiceTimeout        = errors.New("service operation timed out")
)

// ServiceConfig holds configuration for a background service
type ServiceConfig struct {
	Name                string
	ShutdownTimeout     time.Duration
	HealthCheckInterval time.Duration
	RestartOnPanic      bool
	MaxRestartAttempts  int
	RestartDelay        time.Duration
	Logger              Logger
}

// DefaultServiceConfig returns a default service configuration
func DefaultServiceConfig(name string) ServiceConfig {
	return ServiceConfig{
		Name:                name,
		ShutdownTimeout:     30 * time.Second,
		HealthCheckInterval: 30 * time.Second,
		RestartOnPanic:      true,
		MaxRestartAttempts:  3,
		RestartDelay:        5 * time.Second,
		Logger:              &DefaultLogger{},
	}
}

// Logger interface for service logging
type Logger interface {
	Info(msg string, args ...any)
	Error(msg string, args ...any)
	Debug(msg string, args ...any)
	Warn(msg string, args ...any)
}

// DefaultLogger provides a simple logger implementation
type DefaultLogger struct{}

func (l *DefaultLogger) Info(msg string, args ...any) {
	log.Printf("[INFO] "+msg, args...)
}

func (l *DefaultLogger) Error(msg string, args ...any) {
	log.Printf("[ERROR] "+msg, args...)
}

func (l *DefaultLogger) Debug(msg string, args ...any) {
	log.Printf("[DEBUG] "+msg, args...)
}

func (l *DefaultLogger) Warn(msg string, args ...any) {
	log.Printf("[WARN] "+msg, args...)
}

// Worker defines the interface for background work
type Worker interface {
	Run(ctx context.Context) error
	Name() string
	HealthCheck(ctx context.Context) error
}

// ServiceStats holds runtime statistics
type ServiceStats struct {
	StartTime        time.Time
	LastHealthCheck  time.Time
	RestartCount     int
	PanicCount       int
	HealthCheckCount int
	HealthCheckFails int
	IsHealthy        bool
	Uptime           time.Duration
}

// BackgroundService manages a background worker with monitoring and lifecycle management
type BackgroundService struct {
	config     ServiceConfig
	worker     Worker
	state      int
	stateMutex sync.RWMutex

	// Runtime control
	ctx    context.Context
	cancel context.CancelFunc
	wg     sync.WaitGroup

	// Statistics
	stats      ServiceStats
	statsMutex sync.RWMutex

	// Health monitoring
	healthTicker *time.Ticker

	// Error handling
	lastError  error
	errorMutex sync.RWMutex
}

// NewBackgroundService creates a new background service
func NewBackgroundService(config ServiceConfig, worker Worker) *BackgroundService {
	return &BackgroundService{
		config: config,
		worker: worker,
		state:  ServiceStateStopped,
	}
}

// Start begins the background service
func (s *BackgroundService) Start() error {
	s.stateMutex.Lock()
	defer s.stateMutex.Unlock()

	if s.state == ServiceStateRunning || s.state == ServiceStateStarting {
		return ErrServiceAlreadyRunning
	}

	s.state = ServiceStateStarting
	s.ctx, s.cancel = context.WithCancel(context.Background())

	// Initialize stats
	s.updateStats(func(stats *ServiceStats) {
		stats.StartTime = time.Now()
		stats.IsHealthy = true
	})

	// Start health check monitoring
	if s.config.HealthCheckInterval > 0 {
		s.healthTicker = time.NewTicker(s.config.HealthCheckInterval)
		s.wg.Add(1)
		go s.healthCheckLoop()
	}

	// Start main worker
	s.wg.Add(1)
	go s.workerLoop()

	s.state = ServiceStateRunning
	s.config.Logger.Info("Background service '%s' started", s.config.Name)

	return nil
}

// Stop gracefully shuts down the background service
func (s *BackgroundService) Stop() error {
	return s.StopWithTimeout(s.config.ShutdownTimeout)
}

// StopWithTimeout stops the service with a custom timeout
func (s *BackgroundService) StopWithTimeout(timeout time.Duration) error {
	s.stateMutex.Lock()
	if s.state != ServiceStateRunning {
		s.stateMutex.Unlock()
		return ErrServiceNotRunning
	}
	s.state = ServiceStateStopping
	s.stateMutex.Unlock()

	s.config.Logger.Info("Stopping background service '%s'", s.config.Name)

	// Cancel context
	if s.cancel != nil {
		s.cancel()
	}

	// Stop health check ticker
	if s.healthTicker != nil {
		s.healthTicker.Stop()
	}

	// Wait for goroutines to finish with timeout
	done := make(chan struct{})
	go func() {
		s.wg.Wait()
		close(done)
	}()

	select {
	case <-done:
		s.stateMutex.Lock()
		s.state = ServiceStateStopped
		s.stateMutex.Unlock()
		s.config.Logger.Info("Background service '%s' stopped", s.config.Name)
		return nil
	case <-time.After(timeout):
		s.stateMutex.Lock()
		s.state = ServiceStateError
		s.stateMutex.Unlock()
		return ErrServiceTimeout
	}
}

// Restart stops and starts the service
func (s *BackgroundService) Restart() error {
	if err := s.Stop(); err != nil && err != ErrServiceNotRunning {
		return err
	}

	// Wait a bit before restarting
	time.Sleep(s.config.RestartDelay)

	return s.Start()
}

// State returns the current service state
func (s *BackgroundService) State() int {
	s.stateMutex.RLock()
	defer s.stateMutex.RUnlock()
	return s.state
}

// IsRunning returns true if the service is running
func (s *BackgroundService) IsRunning() bool {
	return s.State() == ServiceStateRunning
}

// Stats returns current service statistics
func (s *BackgroundService) Stats() ServiceStats {
	s.statsMutex.RLock()
	defer s.statsMutex.RUnlock()

	stats := s.stats
	if !stats.StartTime.IsZero() {
		stats.Uptime = time.Since(stats.StartTime)
	}

	return stats
}

// LastError returns the last error encountered
func (s *BackgroundService) LastError() error {
	s.errorMutex.RLock()
	defer s.errorMutex.RUnlock()
	return s.lastError
}

// Worker loop with panic recovery and restart logic
func (s *BackgroundService) workerLoop() {
	defer s.wg.Done()

	restartCount := 0

	for {
		select {
		case <-s.ctx.Done():
			return
		default:
		}

		// Run worker with panic recovery
		func() {
			defer func() {
				if r := recover(); r != nil {
					s.updateStats(func(stats *ServiceStats) {
						stats.PanicCount++
					})

					s.setError(fmt.Errorf("worker panic: %v", r))
					s.config.Logger.Error("Worker panic in service '%s': %v", s.config.Name, r)

					// Log stack trace
					buf := make([]byte, 4096)
					n := runtime.Stack(buf, false)
					s.config.Logger.Error("Stack trace:\n%s", string(buf[:n]))

					if s.config.RestartOnPanic && restartCount < s.config.MaxRestartAttempts {
						restartCount++
						s.updateStats(func(stats *ServiceStats) {
							stats.RestartCount++
						})
						s.config.Logger.Info("Restarting worker (attempt %d/%d)", restartCount, s.config.MaxRestartAttempts)

						// Wait before restart
						select {
						case <-time.After(s.config.RestartDelay):
						case <-s.ctx.Done():
							return
						}
					} else {
						s.stateMutex.Lock()
						s.state = ServiceStateError
						s.stateMutex.Unlock()
						return
					}
				}
			}()

			// Run the worker
			if err := s.worker.Run(s.ctx); err != nil {
				if err == context.Canceled {
					return
				}
				s.setError(err)
				s.config.Logger.Error("Worker error in service '%s': %v", s.config.Name, err)
			}
		}()

		// Check if we should continue
		select {
		case <-s.ctx.Done():
			return
		default:
			if s.State() == ServiceStateError {
				return
			}
		}
	}
}

// Health check loop
func (s *BackgroundService) healthCheckLoop() {
	defer s.wg.Done()

	for {
		select {
		case <-s.ctx.Done():
			return
		case <-s.healthTicker.C:
			s.performHealthCheck()
		}
	}
}

// Perform health check
func (s *BackgroundService) performHealthCheck() {
	ctx, cancel := context.WithTimeout(s.ctx, 10*time.Second)
	defer cancel()

	s.updateStats(func(stats *ServiceStats) {
		stats.HealthCheckCount++
		stats.LastHealthCheck = time.Now()
	})

	if err := s.worker.HealthCheck(ctx); err != nil {
		s.updateStats(func(stats *ServiceStats) {
			stats.HealthCheckFails++
			stats.IsHealthy = false
		})
		s.config.Logger.Warn("Health check failed for service '%s': %v", s.config.Name, err)
	} else {
		s.updateStats(func(stats *ServiceStats) {
			stats.IsHealthy = true
		})
		s.config.Logger.Debug("Health check passed for service '%s'", s.config.Name)
	}
}

// Helper methods
func (s *BackgroundService) updateStats(fn func(*ServiceStats)) {
	s.statsMutex.Lock()
	defer s.statsMutex.Unlock()
	fn(&s.stats)
}

func (s *BackgroundService) setError(err error) {
	s.errorMutex.Lock()
	defer s.errorMutex.Unlock()
	s.lastError = err
}

// ServiceManager manages multiple background services
type ServiceManager struct {
	services map[string]*BackgroundService
	mu       sync.RWMutex
}

// NewServiceManager creates a new service manager
func NewServiceManager() *ServiceManager {

	return &ServiceManager{
		services: make(map[string]*BackgroundService),
	}
}

// Register adds a service to the manager
func (sm *ServiceManager) Register(name string, service *BackgroundService) error {
	sm.mu.Lock()
	defer sm.mu.Unlock()

	if _, exists := sm.services[name]; exists {
		return fmt.Errorf("service '%s' already registered", name)
	}

	sm.services[name] = service
	return nil
}

// StartAll starts all registered services
func (sm *ServiceManager) StartAll() error {
	sm.mu.RLock()
	defer sm.mu.RUnlock()

	for name, service := range sm.services {
		if err := service.Start(); err != nil {
			logger.Log.Error("Failed to start service '%s': %v", name, err)
			return err
		}
	}

	return nil
}

// StopAll stops all registered services
func (sm *ServiceManager) StopAll() error {
	sm.mu.RLock()
	defer sm.mu.RUnlock()

	var lastError error
	for name, service := range sm.services {
		if err := service.Stop(); err != nil {
			logger.Log.Error("Failed to stop service '%s': %v", name, err)
			lastError = err
		}
	}

	return lastError
}

// GetService returns a service by name
func (sm *ServiceManager) GetService(name string) (*BackgroundService, bool) {
	sm.mu.RLock()
	defer sm.mu.RUnlock()

	service, exists := sm.services[name]
	return service, exists
}

// RunWithSignals runs all services and handles OS signals for graceful shutdown
func (sm *ServiceManager) RunWithSignals() error {
	// Start all services
	if err := sm.StartAll(); err != nil {
		return err
	}

	// Setup signal handling
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// Wait for signal
	sig := <-sigChan
	logger.Log.Info("Received signal %v, shutting down services", sig)

	// Stop all services
	return sm.StopAll()
}

// Example worker implementations
type ExampleWorker struct {
	name string
}

func (w *ExampleWorker) Name() string {
	return w.name
}

func (w *ExampleWorker) Run(ctx context.Context) error {
	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-ticker.C:
			// Do work here
			log.Printf("Worker %s is working...", w.name)
		}
	}
}

func (w *ExampleWorker) HealthCheck(ctx context.Context) error {
	// Implement health check logic
	return nil
}

// Example usage:
/*
func main() {
	// Create service manager
	manager := NewServiceManager(&DefaultLogger{})

	// Create workers
	worker1 := &ExampleWorker{name: "worker1"}
	worker2 := &ExampleWorker{name: "worker2"}

	// Create services
	config1 := DefaultServiceConfig("service1")
	service1 := NewBackgroundService(config1, worker1)

	config2 := DefaultServiceConfig("service2")
	service2 := NewBackgroundService(config2, worker2)

	// Register services
	manager.Register("service1", service1)
	manager.Register("service2", service2)

	// Run with signal handling
	if err := manager.RunWithSignals(); err != nil {
		log.Fatal(err)
	}
}
*/
