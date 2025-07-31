package dto

import "time"

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

type UserListFilter struct {
	Status    string `json:"status"`
	Plan      string `json:"plan"`
	Search    string `json:"search"`     // Search by name or email
	SortBy    string `json:"sort_by"`    // name, email, created_date, last_login, etc.
	SortOrder string `json:"sort_order"` // asc, desc
	Limit     int    `json:"limit"`
	Offset    int    `json:"offset"`
	Role      string `json:"role"`
}

type UserStats struct {
	TotalUsers        int64 `json:"total_users"`
	ActiveUsers       int64 `json:"active_users"`
	SuspendedUsers    int64 `json:"suspended_users"`
	FreeUsers         int64 `json:"free_users"`
	PaidUsers         int64 `json:"paid_users"`
	NewUsersToday     int64 `json:"new_users_today"`
	NewUsersThisMonth int64 `json:"new_users_this_month"`
}
type User struct {
	ID        string     `json:"id"`
	Name      string     `json:"name"`
	Email     string     `json:"email"`
	Plan      string     `json:"plan_type"`
	Status    string     `json:"status"`
	LastLogin *time.Time `json:"last_login"`
	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`
}

// UserListResponse represents paginated user list response
type UserListResponse struct {
	Users      []User `json:"users"`
	Total      int64  `json:"total"`
	Page       int    `json:"page"`
	PageSize   int    `json:"page_size"`
	TotalPages int    `json:"total_pages"`
}

// UpdateStatusRequest for updating user status
type UpdateStatusRequest struct {
	Status string `json:"status" validate:"required,oneof=activte suspend deactivate"`
}

// UpdatePlanRequest for updating user plan
type UpdatePlanRequest struct {
	Plan string `json:"plan" validate:"required,oneof=free yefe_plus"`
}

type AcceptNotificationRequest struct {
	FcmToken string `json:"fcm_token" validate:"required"`
}

type AcceptInviteDTO struct {
	ConfirmPassword string `json:"confirm_password" validate:"required,eqfield=Password"`
	Password        string `json:"password" validate:"required,min=8"`
	Token           string `json:"token" validate:"required`
}
