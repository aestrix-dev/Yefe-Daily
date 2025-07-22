package fire_base

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"yefe_app/v1/internal/domain"
	"yefe_app/v1/pkg/logger"
	"yefe_app/v1/pkg/utils"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// FCMUserPreferences represents FCM-specific user preferences
type FCMUserPreferences struct {
	ID          uint   `json:"id" gorm:"primaryKey"`
	UserID      string `json:"user_id" gorm:"unique;not null"`
	FCMToken    string `json:"fcm_token"`
	MorningTime string `json:"morning_time"` // Format: "08:30"
	EveningTime string `json:"evening_time"` // Format: "18:00"
	Timezone    string `json:"timezone" gorm:"default:UTC"`
	IsActive    bool   `json:"is_active" gorm:"default:true"`
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

// NotificationRequest represents a notification to be sent
type NotificationRequest struct {
	Token string            `json:"token"`
	Title string            `json:"title"`
	Body  string            `json:"body"`
	Data  map[string]string `json:"data,omitempty"`
}

// FCMCoreService handles Firebase Cloud Messaging operations
type FCMCoreService struct {
	client      *messaging.Client
	db          *gorm.DB
	userUseCase domain.AdminUserUseCase
}

// NewFCMCoreService creates a new FCM core service
func NewFCMCoreService(config utils.FirebaseConfig, userUseCase domain.AdminUserUseCase, dbPath string) (*FCMCoreService, error) {
	// Initialize Firebase
	jsonCreds, err := json.Marshal(config)
	if err != nil {
		return nil, fmt.Errorf("error marshalling firebase config: %v", err)
	}
	opt := option.WithCredentialsJSON(jsonCreds)
	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		return nil, fmt.Errorf("error initializing firebase app: %v", err)
	}

	client, err := app.Messaging(context.Background())
	if err != nil {
		return nil, fmt.Errorf("error getting messaging client: %v", err)
	}

	// Initialize database
	db, err := gorm.Open(sqlite.Open(dbPath), &gorm.Config{})
	if err != nil {
		return nil, fmt.Errorf("failed to connect database: %v", err)
	}

	// Auto migrate the schema
	if err := db.AutoMigrate(&FCMUserPreferences{}); err != nil {
		return nil, fmt.Errorf("failed to migrate database: %v", err)
	}

	return &FCMCoreService{
		client:      client,
		db:          db,
		userUseCase: userUseCase,
	}, nil
}

// SendNotification sends a single notification
func (f *FCMCoreService) SendNotification(ctx context.Context, req NotificationRequest) error {
	message := &messaging.Message{
		Token: req.Token,
		Notification: &messaging.Notification{
			Title: req.Title,
			Body:  req.Body,
		},
		Data: req.Data,
		Webpush: &messaging.WebpushConfig{
			Notification: &messaging.WebpushNotification{
				Title: req.Title,
				Body:  req.Body,
				Icon:  "/icon-192x192.png",
			},
		},
	}

	response, err := f.client.Send(ctx, message)
	if err != nil {
		logger.Log.Errorf("Failed to send notification: %v", err)
		return err
	}

	logger.Log.Infof("Notification sent successfully, message ID: %s", response)
	return nil
}

// SendBulkNotifications sends notifications to multiple tokens
func (f *FCMCoreService) SendBulkNotifications(ctx context.Context, tokens []string, title, body string, data map[string]string) error {
	if len(tokens) == 0 {
		return nil
	}

	// FCM supports up to 500 tokens per request
	batchSize := 500
	for i := 0; i < len(tokens); i += batchSize {
		end := i + batchSize
		if end > len(tokens) {
			end = len(tokens)
		}

		batch := tokens[i:end]
		message := &messaging.MulticastMessage{
			Tokens: batch,
			Notification: &messaging.Notification{
				Title: title,
				Body:  body,
			},
			Data: data,
			Webpush: &messaging.WebpushConfig{
				Notification: &messaging.WebpushNotification{
					Title: title,
					Body:  body,
					Icon:  "/icon-192x192.png",
				},
			},
		}

		response, err := f.client.SendEachForMulticast(ctx, message)
		if err != nil {
			logger.Log.Errorf("Error sending batch notification: %v", err)
			continue
		}

		logger.Log.Infof("Successfully sent %d notifications, failed: %d",
			response.SuccessCount, response.FailureCount)
	}

	return nil
}

// GetActiveUserPreferences returns all active FCM user preferences
func (f *FCMCoreService) GetActiveUserPreferences(ctx context.Context) ([]FCMUserPreferences, error) {
	var preferences []FCMUserPreferences
	if err := f.db.Where("is_active = ? AND fcm_token != ''", true).Find(&preferences).Error; err != nil {
		return nil, fmt.Errorf("failed to get active preferences: %v", err)
	}
	return preferences, nil
}

// GetUserPreferences gets FCM preferences for a specific user
func (f *FCMCoreService) GetUserPreferences(ctx context.Context, userID string) (*FCMUserPreferences, error) {
	var prefs FCMUserPreferences
	if err := f.db.Where("user_id = ?", userID).First(&prefs).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get user preferences: %v", err)
	}
	return &prefs, nil
}

// UpdateUserPreferences updates or creates FCM preferences for a user
func (f *FCMCoreService) UpdateUserPreferences(ctx context.Context, userID string, preferences FCMUserPreferences) error {
	// Validate that user exists
	user, err := f.userUseCase.GetUserByID(ctx, userID)
	if err != nil || user == nil {
		return fmt.Errorf("user not found: %s", userID)
	}

	// Validate time formats
	if preferences.MorningTime != "" && !f.isValidTimeFormat(preferences.MorningTime) {
		return fmt.Errorf("invalid morning time format: %s", preferences.MorningTime)
	}

	if preferences.EveningTime != "" && !f.isValidTimeFormat(preferences.EveningTime) {
		return fmt.Errorf("invalid evening time format: %s", preferences.EveningTime)
	}

	preferences.UserID = userID
	preferences.IsActive = true

	// Upsert preferences
	result := f.db.Where("user_id = ?", userID).FirstOrCreate(&preferences)
	if result.Error != nil {
		return fmt.Errorf("failed to create preferences: %v", result.Error)
	}

	// Update if already exists
	if result.RowsAffected == 0 {
		if err := f.db.Model(&preferences).Where("user_id = ?", userID).Updates(preferences).Error; err != nil {
			return fmt.Errorf("failed to update preferences: %v", err)
		}
	}

	logger.Log.Infof("Updated FCM preferences for user: %s", userID)
	return nil
}

// ValidateUser checks if user exists and has notifications enabled
func (f *FCMCoreService) ValidateUser(ctx context.Context, userID string) (bool, error) {
	user, err := f.userUseCase.GetUserByID(ctx, userID)
	if err != nil || user == nil {
		return false, fmt.Errorf("user not found: %s", userID)
	}

	return true, nil // Default to enabled if preference not found
}

// isValidTimeFormat validates time format
func (f *FCMCoreService) isValidTimeFormat(timeStr string) bool {
	formats := []string{"15:04", "3:04 PM", "3:04 AM"}

	for _, format := range formats {
		if _, err := time.Parse(format, timeStr); err == nil {
			return true
		}
	}

	return false
}

// convertTo24Hour converts 12-hour format to 24-hour format
func ConvertTo24Hour(time12 string) (string, error) {
	// If already in 24-hour format, return as is
	if !strings.Contains(strings.ToUpper(time12), "AM") && !strings.Contains(strings.ToUpper(time12), "PM") {
		return time12, nil
	}

	// Parse 12-hour format
	t, err := time.Parse("3:04 PM", time12)
	if err != nil {
		t, err = time.Parse("15:04", time12)
		if err != nil {
			return "", err
		}
	}

	return t.Format("15:04"), nil
}

// isTimeMatch checks if current time matches scheduled time (within 1 minute)
func (f *FCMCoreService) isTimeMatch(currentTime, scheduledTime string) bool {
	current, err1 := time.Parse("15:04", currentTime)
	scheduled, err2 := time.Parse("15:04", scheduledTime)

	if err1 != nil || err2 != nil {
		return false
	}

	diff := current.Sub(scheduled)
	return diff >= 0 && diff < time.Minute
}
