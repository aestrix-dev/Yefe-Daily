package fire_base

import (
	"context"
	"fmt"
	"time"

	"yefe_app/v1/internal/domain"
	"yefe_app/v1/pkg/logger"
	service "yefe_app/v1/pkg/services"
	"yefe_app/v1/pkg/utils"

	"gorm.io/gorm"
)

// FCMNotificationService orchestrates FCM notifications using background services and scheduler
type FCMNotificationService struct {
	fcmCore        *FCMCoreService
	scheduler      *service.Scheduler
	serviceManager *service.ServiceManager
	ctx            context.Context
	cancel         context.CancelFunc
}

// FCMServiceConfig holds configuration for FCM notification service
type FCMServiceConfig struct {
	Config                 utils.FirebaseConfig
	DatabasePath           string
	NotificationWorkerName string
}

// NewFCMNotificationService creates a new FCM notification service
func NewFCMNotificationService(ctx context.Context, db *gorm.DB, cancel context.CancelFunc, config FCMServiceConfig, userUseCase domain.AdminUserUseCase, scheduler *service.Scheduler) (*FCMNotificationService, error) {

	// Create context for the service

	// Initialize FCM core service
	fcmCore, err := NewFCMCoreService(db, config.Config, userUseCase, config.DatabasePath)
	if err != nil {
		cancel()
		return nil, fmt.Errorf("failed to create FCM core service: %v", err)
	}

	// Create notification worker
	workerName := config.NotificationWorkerName
	if workerName == "" {
		workerName = "fcm-notification-worker"
	}

	// Create background service for the notification worker
	serviceConfig := service.DefaultServiceConfig("fcm-notification-service")
	serviceConfig.HealthCheckInterval = 2 * time.Minute
	serviceConfig.RestartOnPanic = true
	serviceConfig.MaxRestartAttempts = 5
	serviceConfig.RestartDelay = 10 * time.Second

	// Create service manager
	serviceManager := service.NewServiceManager()

	return &FCMNotificationService{
		fcmCore:        fcmCore,
		scheduler:      scheduler,
		serviceManager: serviceManager,
		ctx:            ctx,
		cancel:         cancel,
	}, nil
}

// Start starts all FCM notification services
func (fns *FCMNotificationService) Start() error {
	logger.Log.Info("Starting FCM notification service")

	// Start scheduler
	fns.scheduler.Start()

	// Start background services
	if err := fns.serviceManager.StartAll(); err != nil {
		fns.Stop()
		return fmt.Errorf("failed to start background services: %v", err)
	}

	logger.Log.Info("FCM notification service started successfully")
	return nil
}

// Stop stops all FCM notification services
func (fns *FCMNotificationService) Stop() error {
	logger.Log.Info("Stopping FCM notification service")

	// Stop scheduler
	fns.scheduler.Stop()

	// Stop background services
	if err := fns.serviceManager.StopAll(); err != nil {
		logger.Log.Error("Error stopping background services: %v", err)
	}

	// Cancel context
	fns.cancel()

	logger.Log.Info("FCM notification service stopped")
	return nil
}

// SendNotification sends an immediate notification
func (fns *FCMNotificationService) SendNotification(ctx context.Context, req NotificationRequest) error {
	return fns.fcmCore.SendNotification(ctx, req)
}

// SendBulkNotifications sends bulk notifications
func (fns *FCMNotificationService) SendBulkNotifications(ctx context.Context, tokens []string, title, body string, data map[string]string) error {
	return fns.fcmCore.SendBulkNotifications(ctx, tokens, title, body, data)
}

// ScheduleNotification schedules a one-time notification
func (fns *FCMNotificationService) ScheduleNotification(id, title, body string, token string, runAt time.Time, data map[string]string) error {
	jobName := fmt.Sprintf("fcm-notification-%s", id)

	notificationFunc := func(ctx context.Context) error {
		req := NotificationRequest{
			Token: token,
			Title: title,
			Body:  body,
			Data:  data,
		}
		return fns.fcmCore.SendNotification(ctx, req)
	}

	return fns.scheduler.AddOneTimeJob(id, jobName, runAt, notificationFunc)
}

// ScheduleBulkNotification schedules a bulk notification
func (fns *FCMNotificationService) ScheduleBulkNotification(id, title, body string, tokens []string, runAt time.Time, data map[string]string) error {
	jobName := fmt.Sprintf("fcm-bulk-notification-%s", id)

	notificationFunc := func(ctx context.Context) error {
		return fns.fcmCore.SendBulkNotifications(ctx, tokens, title, body, data)
	}

	return fns.scheduler.AddOneTimeJob(id, jobName, runAt, notificationFunc)
}

// AddRecurringNotification adds a recurring notification job
func (fns *FCMNotificationService) AddRecurringNotification(id, prefId, title, body, cronSchedule string, data map[string]string) error {
	jobName := fmt.Sprintf("fcm-recurring-notification-%s", id)

	notificationFunc := func(ctx context.Context) error {
		pref, err := fns.GetUserPreferences(ctx, prefId)
		if err != nil || !pref.IsActive {
			logger.Log.WithError(err).Error("Error or pref is not active")
			return err
		}
		req := NotificationRequest{Token: pref.FCMToken, Title: title, Body: body, Data: data}
		return fns.fcmCore.SendNotification(ctx, req)
	}

	return fns.scheduler.AddJob(id, jobName, cronSchedule, notificationFunc)
}

// AddRecurringMotivationalNotification adds a recurring notification job with a random motivational message
func (fns *FCMNotificationService) AddRecurringMotivationalNotification(id, prefId, title, cronSchedule string, data map[string]string) error {
	jobName := fmt.Sprintf("fcm-recurring-notification-%s", id)

	notificationFunc := func(ctx context.Context) error {
		pref, err := fns.GetUserPreferences(ctx, prefId)
		if err != nil || !pref.IsActive {
			logger.Log.WithError(err).Error("Error or pref is not active")
			return err
		}
		req := NotificationRequest{Token: pref.FCMToken, Title: title, Body: utils.GetRandomMessage(), Data: data}
		return fns.fcmCore.SendNotification(ctx, req)
	}

	return fns.scheduler.AddJob(id, jobName, cronSchedule, notificationFunc)
}

// RemoveScheduledNotification removes a scheduled notification
func (fns *FCMNotificationService) RemoveScheduledNotification(id string) error {
	return fns.scheduler.RemoveJob(id)
}

// GetUserPreferences gets FCM preferences for a user
func (fns *FCMNotificationService) GetUserPreferences(ctx context.Context, userID string) (*FCMUserPreferences, error) {
	return fns.fcmCore.GetUserPreferences(ctx, userID)
}

// UpdateUserPreferences updates FCM preferences for a user
func (fns *FCMNotificationService) UpdateUserPreferences(ctx context.Context, userID string, preferences FCMUserPreferences) error {
	return fns.fcmCore.UpdateUserPreferences(ctx, userID, preferences)
}

// GetSchedulerJobs returns all scheduled jobs
func (fns *FCMNotificationService) GetSchedulerJobs() map[string]*service.Job {
	return fns.scheduler.GetJobs()
}

// GetJobResults returns recent job execution results
func (fns *FCMNotificationService) GetJobResults(limit int) []service.JobResult {
	return fns.scheduler.GetResults(limit)
}

// RunWithSignals runs the service and handles OS signals for graceful shutdown
func (fns *FCMNotificationService) RunWithSignals() error {
	// Start the service
	if err := fns.Start(); err != nil {
		return err
	}

	// Use service manager's signal handling
	return fns.serviceManager.RunWithSignals()
}
