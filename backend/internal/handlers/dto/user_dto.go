package dto

type ReminderRequest struct {
	MorningReminder string `json:"morning_reminder" validate:"required"`
	EveningReminder string `json:"evening_reminder" validate:"required"`
}

type UserPrefsRequest struct {
	MorningPrompt     bool            `json:"morning_prompt"`
	EveningReflection bool            `json:"evening_reflection"`
	Challenge         bool            `json:"challenge"`
  Language          string          `json:"language" validate:"required,oneof=English French Spanish Portuguese"`
	Reminders         ReminderRequest `json:"reminders"`
}

// Request/Response DTOs
type RegisterRequest struct {
	Email           string           `json:"email" validate:"required,email"`
	Name            string           `json:"Name" validate:"required,min=3,max=50"`
	Password        string           `json:"password" validate:"required,min=8"`
	Prefs           UserPrefsRequest `json:"user_prefs" validate:"required"`
	ConfirmPassword string           `json:"confirm_password" validate:"required,eqfield=Password"`
	IPAddress       string           `json:"-"`
	UserAgent       string           `json:"-"`
}

type LoginRequest struct {
	Email     string `json:"email" validate:"required,email"`
	Password  string `json:"password" validate:"required"`
	IPAddress string `json:"-"`
	UserAgent string `json:"-"`
}

type LoginResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int64  `json:"expires_in"`
}

type LogoutRequest struct {
	SessionID string `json:"session_id" validate:"required"`
	IPAddress string `json:"-"`
	UserAgent string `json:"-"`
}
