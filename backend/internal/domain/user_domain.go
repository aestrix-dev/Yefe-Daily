package domain

import (
	"context"
	"time"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/types"
)

type UserType string

const (
	FreeUser UserType = "free"
	ProUser  UserType = "pro"
)

type MetricData struct {
	Value      int     `json:"value"`
	Change     float64 `json:"change"`
	ChangeType string  `json:"changeType"`
}

type ActivityItem struct {
	ID          string                  `json:"id"`
	Type        types.SecurityEventType `json:"type"`
	User        string                  `json:"user"`
	Description types.JSONMap           `json:"description"`
	TimeAgo     string                  `json:"timeAgo"`
}

type MonthlyRegistrations struct {
	Month string `json:"month"`
	Count int    `json:"count"`
}

type QuickInsights struct {
	PremiumConversionRate float64 `json:"premiumConversionRate"`
	ActiveUsersToday      int     `json:"activeUsersToday"`
	PendingInvitations    int     `json:"pendingInvitations"`
}

type DashboardData struct {
	TotalUsers            MetricData             `json:"totalUsers"`
	PremiumSubscribers    MetricData             `json:"premiumSubscribers"`
	RecentActivity        []ActivityItem         `json:"recentActivity"`
	QuickInsights         QuickInsights          `json:"quickInsights"`
	LastUpdated           time.Time              `json:"lastUpdated"`
	MonthleyRegistrations []MonthlyRegistrations `json:"MonthleyRegistrations"`
}

type AdminInvitation struct {
	ID              string    `json:"id"`
	Email           string    `json:"email"`
	Role            string    `json:"role"`
	InvitedBy       string    `json:"invited_by"`
	InvitationToken string    `json:"invitation_token"`
	Status          string    `json:"status"`
	ExpiresAt       time.Time `json:"expires_at"`
}

type User struct {
	ID                 string       `json:"id"`
	Email              string       `json:"email"`
	Name               string       `json:"Name"`
	PasswordHash       string       `json:"-"`
	Salt               string       `json:"-"`
	IsEmailVerified    bool         `json:"is_email_verified"`
	IsActive           bool         `json:"is_active"`
	FailedLoginCount   int          `json:"-"`
	LastFailedLogin    *time.Time   `json:"-"`
	AccountLockedUntil *time.Time   `json:"-"`
	CreatedAt          time.Time    `json:"created_at"`
	UpdatedAt          time.Time    `json:"updated_at"`
	LastLoginAt        *time.Time   `json:"last_login_at"`
	LastLoginIP        string       `json:"-"`
	Profile            *UserProfile `json:"user_profile"`
	Role               string       `json:"role"`

	PlanType      string     `json:"plan_type"`
	PlanName      string     `json:"plan_name"`
	PlanStartDate time.Time  `json:"plan_start_date"`
	PlanEndDate   *time.Time `json:"plan_end_date"`
	PlanAutoRenew bool       `json:"plan_auto_renew"`
	PlanStatus    string     `json:"plan_status"`
}

type UserProfile struct {
	ID                      string                  `json:"id"`
	UserID                  string                  `json:"user_id"`
	DateOfBirth             *time.Time              `json:"date_of_birth"`
	PhoneNumber             string                  `json:"phone_number"`
	Bio                     string                  `json:"bio"`
	Location                string                  `json:"location"`
	NotificationPreferences types.NotificationsPref `json:"notification_preferences"`
	CreatedAt               time.Time               `json:"created_at"`
	UpdatedAt               time.Time               `json:"updated_at"`
}

type DashboardUsecase interface {
	GetDashboardData(ctx context.Context) (*DashboardData, error)
}

type UserRepository interface {
	Create(ctx context.Context, user *User, notificationsPrefs types.NotificationsPref) error
	GetByID(ctx context.Context, id string) (*User, error)
	GetByEmail(ctx context.Context, email string) (*User, error)
	Update(ctx context.Context, user *User) error
	Delete(ctx context.Context, id string) error
	UpdateLastLogin(ctx context.Context, userID string) error
	CreateAdminUser(ctx context.Context, user *User, role string) error
	UpdateUserRole(ctx context.Context, userID string, role string) error
}

type UserProfileRepository interface {
	Create(ctx context.Context, profile *UserProfile) error
	GetByID(ctx context.Context, id string) (*UserProfile, error)
	GetByUserID(ctx context.Context, userID string) (*UserProfile, error)
	Update(ctx context.Context, profile *UserProfile) error
	UpdatePartial(ctx context.Context, id string, updates map[string]any) error
	Delete(ctx context.Context, id string) error
	UpdateAvatar(ctx context.Context, userID, avatarURL string) error
	UpdateNotificationPreferences(ctx context.Context, userID string, prefs types.NotificationsPref) error
	Count(ctx context.Context) (int64, error)
	Exists(ctx context.Context, userID string) (bool, error)
}
type FCMRepository interface {
	GetFCMToken(ctx context.Context, userID string) (string, error)
}

type AdminUserRepository interface {
	GetAllUsers(ctx context.Context, filter dto.UserListFilter) (dto.UserListResponse, error)
	GetUserStats(ctx context.Context) (dto.UserStats, error)
	UpdateUserStatus(ctx context.Context, userID string, status bool) error
	UpdateUserPlan(ctx context.Context, userID string, plan string) error
	// New methods for admin invitation
	InviteAdmin(ctx context.Context, invitation AdminInvitation) error
	GetAdminInvitations(ctx context.Context) ([]AdminInvitation, error)
	GetAdminInvitationByID(ctx context.Context, token string) (*AdminInvitation, error)
	UpdateInvitationStatus(ctx context.Context, invitationID string, status string) error
	GetMonthlyAnylics(ctx context.Context) ([]MonthlyRegistrations, error)
}
type AdminUserUseCase interface {
	// Admin-specific operations
	GetAllUsers(ctx context.Context, filter dto.UserListFilter) (dto.UserListResponse, error)
	UpdateUserStatus(ctx context.Context, userID string, status string) error
	UpdateUserPlan(ctx context.Context, userID string, plan string) error
	// New methods for admin invitation
	InviteNewAdmin(ctx context.Context, req dto.AdminInvitationEmailRequest, invitedBy string) error
	GetPendingInvitations(ctx context.Context) ([]AdminInvitation, error)
	AcceptInvitation(ctx context.Context, invitationRequst dto.AcceptInviteDTO) error
	GetUserByID(ctx context.Context, userID string) (*User, error)
	GetMonthlyAnylics(ctx context.Context) ([]MonthlyRegistrations, error)
	DeleteUser(ctx context.Context, userID string) error
	GetUserFCMToken(ctx context.Context, userID string) (string, error)
}
type AuthUseCase interface {
	Register(ctx context.Context, req dto.RegisterRequest) (*User, error)
	Login(ctx context.Context, req dto.LoginRequest) (*dto.LoginResponse, error)
	Logout(ctx context.Context, req dto.LogoutRequest) error
	AcceptNotificaions(ctx context.Context, fcmToken string, user *User) error
	//RefreshToken(ctx context.Context, refreshToken string) (*dto.LoginResponse, error)
	//LogoutAll(ctx context.Context, userID string) error
	//VerifyEmail(ctx context.Context, token string) error
	//ForgotPassword(ctx context.Context, email string) error
	//ResetPassword(ctx context.Context, token, newPassword string) error
	//ChangePassword(ctx context.Context, userID, currentPassword, newPassword string) error
}

// Helper methods for plan management
func (u *User) IsFreePlan() bool {
	return u.PlanType == "free"
}

func (u *User) IsYefePlusPlan() bool {
	return u.PlanType == "yefe_plus"
}

func (u *User) GetActivePlanName() string {
	return u.PlanName
}

func (u *User) IsActivePlan() bool {
	return u.PlanStatus == "active"
}

func (u *User) IsPlanExpired() bool {
	if u.PlanEndDate == nil {
		return false // Free plan never expires
	}
	return time.Now().After(*u.PlanEndDate)
}

func (u *User) IsAdmin() bool {
	return u.Role == "admin"
}

func (u *User) IsUser() bool {
	return u.Role == "user"
}

func (u *User) SetAsAdmin() {
	u.Role = "admin"
}

func (u *User) SetAsUser() {
	u.Role = "user"
}

func (u *User) UpgradeToYefePlus(endDate *time.Time, autoRenew bool) {
	u.PlanType = "yefe_plus"
	u.PlanName = "Yefe Plus"
	u.PlanStartDate = time.Now()
	u.PlanEndDate = endDate
	u.PlanAutoRenew = autoRenew
	u.PlanStatus = "active"
}

func (u *User) DowngradeToFree() {
	u.PlanType = "free"
	u.PlanName = "Free"
	u.PlanStartDate = time.Now()
	u.PlanEndDate = nil
	u.PlanAutoRenew = false
	u.PlanStatus = "active"
}

func (u *User) CancelPlan() {
	u.PlanStatus = "cancelled"
	u.PlanAutoRenew = false
}

func (u *User) GetPlanFeatures() map[string]any {
	if u.PlanType == "yefe_plus" {
		return map[string]any{
			"api_calls":        10000,
			"storage_gb":       10,
			"projects":         -1,
			"priority_support": true,
		}
	}

	// Default free plan features
	return map[string]any{
		"api_calls":        1000,
		"storage_gb":       1,
		"projects":         3,
		"priority_support": false,
	}
}
