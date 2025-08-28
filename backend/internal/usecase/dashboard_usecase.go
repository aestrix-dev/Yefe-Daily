package usecase

import (
	"context"
	"fmt"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
)

type DashboardUsecase interface {
	GetDashboardData(ctx context.Context) (*domain.DashboardData, error)
}

type dashboardUsecase struct {
	adminUseCase    domain.AdminUserUseCase
	activityUseCase domain.UserActivityUsecase
}

func NewDashboardUsecase(admin domain.AdminUserUseCase, activity domain.UserActivityUsecase) DashboardUsecase {
	return &dashboardUsecase{
		adminUseCase:    admin,
		activityUseCase: activity,
	}
}

func (u *dashboardUsecase) GetDashboardData(ctx context.Context) (*domain.DashboardData, error) {
	type result struct {
		data interface{}
		err  error
	}

	userStatsC := make(chan result, 1)
	activityC := make(chan result, 1)
	insightsC := make(chan result, 1)
	monthlyRegC := make(chan result, 1)

	// Fetch user stats
	go func() {
		stats, err := u.getUserStats(ctx)
		userStatsC <- result{stats, err}
	}()

	// Fetch activity
	go func() {
		activity, err := u.getRecentActivity(ctx)
		activityC <- result{activity, err}
	}()

	// Fetch quick insights
	go func() {
		insights, err := u.getQuickInsights(ctx)
		insightsC <- result{insights, err}
	}()

	// Fetch monthly reg
	go func() {
		monthlyReg, err := u.adminUseCase.GetMonthlyAnylics(ctx)
		monthlyRegC <- result{monthlyReg, err}
	}()

	// Receive results
	userStatsRes := <-userStatsC
	activityRes := <-activityC
	insightsRes := <-insightsC
	monthlyRes := <-monthlyRegC

	if userStatsRes.err != nil {
		return nil, fmt.Errorf("user stats error: %w", userStatsRes.err)
	}

	if activityRes.err != nil {
		return nil, fmt.Errorf("activity fetch error: %w", activityRes.err)
	}

	if insightsRes.err != nil {
		return nil, fmt.Errorf("insights error: %w", insightsRes.err)
	}

	if monthlyRes.err != nil {
		return nil, fmt.Errorf("Could not get monthly reg error: %w", monthlyRes.err)
	}

	userStats := userStatsRes.data.(map[string]domain.MetricData)
	activity := activityRes.data.([]domain.ActivityItem)
	insights := insightsRes.data.(domain.QuickInsights)
	monthlyReg := monthlyRes.data.([]domain.MonthlyRegistrations)

	return &domain.DashboardData{
		TotalUsers:            userStats["totalUsers"],
		PremiumSubscribers:    userStats["premiumSubscribers"],
		RecentActivity:        activity,
		QuickInsights:         insights,
		LastUpdated:           time.Now(),
		MonthleyRegistrations: monthlyReg,
	}, nil
}

func (u *dashboardUsecase) getUserStats(ctx context.Context) (map[string]domain.MetricData, error) {
	filter := dto.UserListFilter{Limit: 10000, Offset: 0}
	allUsers, err := u.adminUseCase.GetAllUsers(ctx, filter)
	if err != nil {
		return nil, err
	}
	premiumCount := 0
	for _, user := range allUsers.Users {
		if user.Plan == "yefe_plus" {
			premiumCount++
		}
	}

	dailyTrend, dailyTrendAvg := u.getRegistrationStats(ctx, allUsers.Users)
	premimumTrend, premimumTrendAvg := u.getPremiumStats(ctx, allUsers.Users)

	return map[string]domain.MetricData{
		"totalUsers": {
			Value:      int(allUsers.Total),
			Change:     dailyTrendAvg,
			ChangeType: dailyTrend,
		},
		"premiumSubscribers": {
			Value:      premiumCount,
			Change:     premimumTrendAvg,
			ChangeType: premimumTrend,
		},
	}, nil
}

func (u *dashboardUsecase) getRegistrationStats(ctx context.Context, allUsers []dto.User) (string, float64) {

	now := time.Now()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	yesterday := today.AddDate(0, 0, -1)

	var yesterdayCount, todayCount int

	// Count users registered yesterday and today
	for _, user := range allUsers {
		userDate := time.Date(user.CreatedAt.Year(), user.CreatedAt.Month(), user.CreatedAt.Day(), 0, 0, 0, 0, user.CreatedAt.Location())

		if userDate.Equal(yesterday) {
			yesterdayCount++
		} else if userDate.Equal(today) {
			todayCount++
		}
	}

	// Calculate averages (assuming 24 hours for daily average)
	todayAvg := float64(todayCount) / 24.0

	// Determine trend
	var trend string
	if todayCount > yesterdayCount {
		trend = "increase"
	} else if todayCount < yesterdayCount {
		trend = "decrease"
	} else {
		trend = "same"
	}
	return trend, todayAvg
}

func (u *dashboardUsecase) getPremiumStats(ctx context.Context, allUsers []dto.User) (string, float64) {

	now := time.Now()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	yesterday := today.AddDate(0, 0, -1)

	var yesterdayCount, todayCount int

	// Count users registered yesterday and today
	for _, user := range allUsers {
		userDate := time.Date(user.CreatedAt.Year(), user.CreatedAt.Month(), user.CreatedAt.Day(), 0, 0, 0, 0, user.CreatedAt.Location())

		if user.Plan == "premium" {
			if userDate.Equal(yesterday) {
				yesterdayCount++
			} else if userDate.Equal(today) {
				todayCount++
			}
		}
	}

	// Calculate averages (assuming 24 hours for daily average)
	todayAvg := float64(todayCount) / 24.0

	// Determine trend
	var trend string
	if todayCount > yesterdayCount {
		trend = "increase"
	} else if todayCount < yesterdayCount {
		trend = "decrease"
	} else {
		trend = "same"
	}
	return trend, todayAvg
}

func (u *dashboardUsecase) getRecentActivity(ctx context.Context) ([]domain.ActivityItem, error) {
	events, err := u.activityUseCase.GetRecentActivity(ctx, 10)
	if err != nil {
		return nil, err
	}

	var activities []domain.ActivityItem
	for _, event := range events {
		user, err := u.adminUseCase.GetUserByID(ctx, event.UserID)
		userEmail := event.UserID
		if err == nil {
			userEmail = user.Email
		}

		activities = append(activities, domain.ActivityItem{
			ID:          event.ID,
			Type:        event.EventType,
			User:        userEmail,
			Description: event.Details,
			TimeAgo:     u.formatTimeAgo(event.CreatedAt),
		})
	}

	return activities, nil
}

func (u *dashboardUsecase) getQuickInsights(ctx context.Context) (domain.QuickInsights, error) {
	filter := dto.UserListFilter{Limit: 10000, Offset: 0}
	allUsers, err := u.adminUseCase.GetAllUsers(ctx, filter)
	if err != nil {
		return domain.QuickInsights{}, err
	}

	now := time.Now()
	premiumCount := 0
	activeToday := 0

	for _, user := range allUsers.Users {
		if user.Plan == "yefe_plus" {
			premiumCount++
		}
		if user.LastLogin != nil && user.LastLogin.After(now.Add(-24*time.Hour)) {
			activeToday++
		}
	}

	conversionRate := 0.0
	if len(allUsers.Users) > 0 {
		conversionRate = float64(premiumCount) / float64(len(allUsers.Users)) * 100
	}

	invitations, err := u.adminUseCase.GetPendingInvitations(ctx)
	if err != nil {
		return domain.QuickInsights{}, err
	}

	return domain.QuickInsights{
		PremiumConversionRate: conversionRate,
		ActiveUsersToday:      activeToday,
		PendingInvitations:    len(invitations),
	}, nil
}

func (u *dashboardUsecase) formatTimeAgo(t time.Time) string {
	duration := time.Since(t)
	if duration < time.Minute {
		return "just now"
	}
	if duration < time.Hour {
		return fmt.Sprintf("%d minutes ago", int(duration.Minutes()))
	}
	if duration < 24*time.Hour {
		return fmt.Sprintf("%d hours ago", int(duration.Hours()))
	}
	return fmt.Sprintf("%d days ago", int(duration.Hours()/24))
}
