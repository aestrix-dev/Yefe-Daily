package usecase

import (
	"errors"
	"fmt"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
)

// challengeUseCase implements the ChallengeUseCase interface
type challengeUseCase struct {
	challengeRepo     domain.ChallengeRepository
	userChallengeRepo domain.UserChallengeRepository
	statsRepo         domain.ChallengeStatsRepository
}

// NewChallengeUseCase creates a new instance of challengeUseCase
func NewChallengeUseCase(
	challengeRepo domain.ChallengeRepository,
	userChallengeRepo domain.UserChallengeRepository,
	statsRepo domain.ChallengeStatsRepository,
) domain.ChallengeUseCase {
	return &challengeUseCase{
		challengeRepo:     challengeRepo,
		userChallengeRepo: userChallengeRepo,
		statsRepo:         statsRepo,
	}
}

// GetUserChallengesForToday retrieves all challenges assigned to a user for today
func (uc *challengeUseCase) GetUserChallengesForToday(userID string) ([]domain.UserChallenge, error) {
	if userID == "" {
		return nil, errors.New("user ID cannot be empty")
	}

	userChallenges, err := uc.userChallengeRepo.GetTodaysUserChallenges(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user's today challenges: %w", err)
	}

	return userChallenges, nil
}

// GetUserChallengeHistory retrieves user's challenge history
func (uc *challengeUseCase) GetUserChallengeHistory(userID string, limit int) ([]domain.UserChallenge, error) {
	if userID == "" {
		return nil, errors.New("user ID cannot be empty")
	}

	userChallenges, err := uc.userChallengeRepo.GetUserChallengesByUserID(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user challenge history: %w", err)
	}

	// Apply limit if specified
	if limit > 0 && len(userChallenges) > limit {
		userChallenges = userChallenges[:limit]
	}

	return userChallenges, nil
}

// CompleteChallenge marks a challenge as completed for a user
func (uc *challengeUseCase) CompleteChallenge(userID, challengeID string) error {
	if userID == "" {
		return errors.New("user ID cannot be empty")
	}
	if challengeID == "" {
		return errors.New("challenge ID cannot be empty")
	}

	// Get the user challenge
	userChallenges, err := uc.userChallengeRepo.GetUserChallengesByUserID(userID)
	if err != nil {
		return fmt.Errorf("failed to get user challenges: %w", err)
	}

	var userChallenge domain.UserChallenge
	for _, uc := range userChallenges {
		if uc.ChallengeID == challengeID {
			userChallenge = uc
			break
		}
	}

	if userChallenge.Status == dto.StatusCompleted {
		return errors.New("challenge already completed")
	}

	// Update challenge status
	now := time.Now()
	userChallenge.Status = dto.StatusCompleted
	userChallenge.CompletedAt = &now
	userChallenge.UpdatedAt = now

	err = uc.userChallengeRepo.UpdateUserChallenge(userChallenge)
	if err != nil {
		return fmt.Errorf("failed to update user challenge: %w", err)
	}

	// Update user statistics
	err = uc.updateUserStatsAfterCompletion(userID, challengeID)
	if err != nil {
		return fmt.Errorf("failed to update user stats: %w", err)
	}

	return nil
}

// MarkChallengeAsSkipped marks a challenge as skipped for a user
func (uc *challengeUseCase) MarkChallengeAsSkipped(userID, challengeID string) error {
	if userID == "" {
		return errors.New("user ID cannot be empty")
	}
	if challengeID == "" {
		return errors.New("challenge ID cannot be empty")
	}

	// Get the user challenge
	userChallenges, err := uc.userChallengeRepo.GetUserChallengesByUserID(userID)
	if err != nil {
		return fmt.Errorf("failed to get user challenges: %w", err)
	}

	var userChallenge domain.UserChallenge
	for _, uc := range userChallenges {
		if uc.ChallengeID == challengeID {
			userChallenge = uc
			break
		}
	}

	if userChallenge.Status != dto.StatusPending {
		return errors.New("can only skip pending challenges")
	}

	// Update challenge status
	userChallenge.Status = dto.StatusSkipped
	userChallenge.UpdatedAt = time.Now()

	err = uc.userChallengeRepo.UpdateUserChallenge(userChallenge)
	if err != nil {
		return fmt.Errorf("failed to update user challenge: %w", err)
	}

	// Update user statistics (reset streak if needed)
	err = uc.updateUserStatsAfterSkip(userID)
	if err != nil {
		return fmt.Errorf("failed to update user stats: %w", err)
	}

	return nil
}

// GetUserStats retrieves user's challenge statistics
func (uc *challengeUseCase) GetUserStats(userID string) (domain.ChallengeStats, error) {
	if userID == "" {
		return domain.ChallengeStats{}, errors.New("user ID cannot be empty")
	}

	stats, err := uc.statsRepo.GetUserStats(userID)
	if err != nil {
		return domain.ChallengeStats{}, fmt.Errorf("failed to get user stats: %w", err)
	}

	return stats, nil
}

// GetUserProgress retrieves user's progress for a specific period
func (uc *challengeUseCase) GetUserProgress(userID string, period string) (map[string]any, error) {
	if userID == "" {
		return nil, errors.New("user ID cannot be empty")
	}

	var startDate time.Time
	now := time.Now()

	switch period {
	case "weekly":
		startDate = now.AddDate(0, 0, -7)
	case "monthly":
		startDate = now.AddDate(0, -1, 0)
	case "yearly":
		startDate = now.AddDate(-1, 0, 0)
	default:
		return nil, errors.New("invalid period. Use 'weekly', 'monthly', or 'yearly'")
	}

	// Get user challenges for the period
	userChallenges, err := uc.userChallengeRepo.GetUserChallengesByUserID(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user challenges: %w", err)
	}

	// Filter challenges within the period
	var periodChallenges []domain.UserChallenge
	for _, uc := range userChallenges {
		if uc.CreatedAt.After(startDate) {
			periodChallenges = append(periodChallenges, uc)
		}
	}

	// Calculate progress metrics
	totalChallenges := len(periodChallenges)
	completedChallenges := 0
	skippedChallenges := 0
	totalPoints := 0

	for _, uc_ := range periodChallenges {
		switch uc_.Status {
		case dto.StatusCompleted:
			completedChallenges++
			// Get challenge details to add points
			challenge, err := uc.challengeRepo.GetChallengeByID(uc_.ChallengeID)
			if err == nil {
				totalPoints += challenge.Points
			}
		case dto.StatusSkipped:
			skippedChallenges++
		}
	}

	completionRate := 0.0
	if totalChallenges > 0 {
		completionRate = float64(completedChallenges) / float64(totalChallenges) * 100
	}

	progress := map[string]any{
		"period":               period,
		"total_challenges":     totalChallenges,
		"completed_challenges": completedChallenges,
		"skipped_challenges":   skippedChallenges,
		"pending_challenges":   totalChallenges - completedChallenges - skippedChallenges,
		"completion_rate":      completionRate,
		"total_points":         totalPoints,
		"start_date":           startDate,
		"end_date":             now,
	}

	return progress, nil
}

// GetLeaderboard retrieves the leaderboard
func (uc *challengeUseCase) GetLeaderboard(limit int) ([]domain.ChallengeStats, error) {
	leaderboard, err := uc.statsRepo.GetLeaderboard(limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get leaderboard: %w", err)
	}

	return leaderboard, nil
}

// GetChallengesByType retrieves challenges by type
func (uc *challengeUseCase) GetChallengesByType(challengeType string, limit int) ([]domain.Challenge, error) {
	if challengeType == "" {
		return nil, errors.New("challenge type cannot be empty")
	}

	challenges, err := uc.challengeRepo.GetChallengesByType(challengeType, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get challenges by type: %w", err)
	}

	return challenges, nil
}

// GetAvailableChallengeTypes returns all available challenge types
func (uc *challengeUseCase) GetAvailableChallengeTypes() ([]string, error) {
	types := []string{
		domain.ChallengeMorningPrayer,
		domain.ChallengeScriptureMemorization,
		domain.ChallengeActsOfService,
		domain.ChallengeManhoodChallenge,
	}

	return types, nil
}

// Helper methods

// updateUserStatsAfterCompletion updates user statistics after completing a challenge
func (uc *challengeUseCase) updateUserStatsAfterCompletion(userID, challengeID string) error {
	// Get current stats
	stats, err := uc.statsRepo.GetUserStats(userID)
	if err != nil {
		// If stats don't exist, create new ones
		stats = domain.ChallengeStats{
			UserID:          userID,
			TotalChallenges: 0,
			CompletedCount:  0,
			TotalPoints:     0,
			CurrentStreak:   0,
			LongestStreak:   0,
		}
	}

	// Get challenge details for points
	challenge, err := uc.challengeRepo.GetChallengeByID(challengeID)
	if err != nil {
		return fmt.Errorf("failed to get challenge details: %w", err)
	}

	// Update stats
	stats.CompletedCount++
	stats.TotalPoints += challenge.Points
	stats.CurrentStreak++

	if stats.CurrentStreak > stats.LongestStreak {
		stats.LongestStreak = stats.CurrentStreak
	}

	// Update total challenges count
	userChallenges, err := uc.userChallengeRepo.GetUserChallengesByUserID(userID)
	if err != nil {
		return fmt.Errorf("failed to get user challenges for stats update: %w", err)
	}
	stats.TotalChallenges = len(userChallenges)

	// Save updated stats
	err = uc.statsRepo.UpdateUserStats(stats)
	if err != nil {
		return fmt.Errorf("failed to update user stats: %w", err)
	}

	return nil
}

// updateUserStatsAfterSkip updates user statistics after skipping a challenge
func (uc *challengeUseCase) updateUserStatsAfterSkip(userID string) error {
	// Get current stats
	stats, err := uc.statsRepo.GetUserStats(userID)
	if err != nil {
		return fmt.Errorf("failed to get user stats: %w", err)
	}

	// Reset current streak when skipping
	stats.CurrentStreak = 0

	// Update total challenges count
	userChallenges, err := uc.userChallengeRepo.GetUserChallengesByUserID(userID)
	if err != nil {
		return fmt.Errorf("failed to get user challenges for stats update: %w", err)
	}
	stats.TotalChallenges = len(userChallenges)

	// Save updated stats
	err = uc.statsRepo.UpdateUserStats(stats)
	if err != nil {
		return fmt.Errorf("failed to update user stats: %w", err)
	}

	return nil
}

// generateID generates a unique ID for challenges and user challenges
// You should replace this with your preferred ID generation method
func generateID() string {
	return fmt.Sprintf("%d", time.Now().UnixNano())
}

// DashboardUseCase handles dashboard-specific operations
type DashboardUseCase struct {
	challengeUseCase  domain.ChallengeUseCase
	challengeRepo     domain.ChallengeRepository
	userChallengeRepo domain.UserChallengeRepository
	statsRepo         domain.ChallengeStatsRepository
}

// NewDashboardUseCase creates a new dashboard use case
func NewDashboardUseCase(
	challengeUseCase domain.ChallengeUseCase,
	challengeRepo domain.ChallengeRepository,
	userChallengeRepo domain.UserChallengeRepository,
	statsRepo domain.ChallengeStatsRepository,
) *DashboardUseCase {
	return &DashboardUseCase{
		challengeUseCase:  challengeUseCase,
		challengeRepo:     challengeRepo,
		userChallengeRepo: userChallengeRepo,
		statsRepo:         statsRepo,
	}
}

// GetDashboardData retrieves all data needed for the user dashboard
func (uc *DashboardUseCase) GetDashboardData(userID string) (*dto.DashboardResponse, error) {
	if userID == "" {
		return nil, errors.New("user ID cannot be empty")
	}

	// Get today's challenges for the user
	todaysUserChallenges, err := uc.challengeUseCase.GetUserChallengesForToday(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get today's challenges: %w", err)
	}

	// Convert to challenge responses
	todaysChallenges := make([]*dto.ChallengeResponse, len(todaysUserChallenges))
	for i, userChallenge := range todaysUserChallenges {
		challenge, err := uc.challengeRepo.GetChallengeByID(userChallenge.ChallengeID)
		if err != nil {
			return nil, fmt.Errorf("failed to get challenge details: %w", err)
		}

		// Convert domain entities to DTOs
		challengeDTO := &dto.ChallengeDTO{
			ID:          challenge.ID,
			Title:       challenge.Title,
			Description: challenge.Description,
			Type:        challenge.Type,
			Points:      challenge.Points,
			Date:        challenge.Date,
			CreatedAt:   challenge.CreatedAt,
			UpdatedAt:   challenge.UpdatedAt,
		}

		userChallengeDTO := &dto.UserChallengeDTO{
			ID:          userChallenge.ID,
			UserID:      userChallenge.UserID,
			ChallengeID: userChallenge.ChallengeID,
			Status:      userChallenge.Status,
			CompletedAt: userChallenge.CompletedAt,
			CreatedAt:   userChallenge.CreatedAt,
			UpdatedAt:   userChallenge.UpdatedAt,
		}

		todaysChallenges[i] = &dto.ChallengeResponse{
			Challenge:     challengeDTO,
			UserChallenge: userChallengeDTO,
			IsCompleted:   userChallenge.Status == dto.StatusCompleted,
			CanComplete:   userChallenge.Status == dto.StatusPending,
		}
	}

	// Get recently completed challenges
	recentlyCompletedUserChallenges, err := uc.userChallengeRepo.GetCompletedChallenges(userID, 5)
	if err != nil {
		return nil, fmt.Errorf("failed to get recently completed challenges: %w", err)
	}

	recentlyCompleted := make([]*dto.ChallengeResponse, len(recentlyCompletedUserChallenges))
	for i, userChallenge := range recentlyCompletedUserChallenges {
		challenge, err := uc.challengeRepo.GetChallengeByID(userChallenge.ChallengeID)
		if err != nil {
			return nil, fmt.Errorf("failed to get challenge details: %w", err)
		}

		// Convert domain entities to DTOs
		challengeDTO := &dto.ChallengeDTO{
			ID:          challenge.ID,
			Title:       challenge.Title,
			Description: challenge.Description,
			Type:        challenge.Type,
			Points:      challenge.Points,
			Date:        challenge.Date,
			CreatedAt:   challenge.CreatedAt,
			UpdatedAt:   challenge.UpdatedAt,
		}

		userChallengeDTO := &dto.UserChallengeDTO{
			ID:          userChallenge.ID,
			UserID:      userChallenge.UserID,
			ChallengeID: userChallenge.ChallengeID,
			Status:      userChallenge.Status,
			CompletedAt: userChallenge.CompletedAt,
			CreatedAt:   userChallenge.CreatedAt,
			UpdatedAt:   userChallenge.UpdatedAt,
		}

		recentlyCompleted[i] = &dto.ChallengeResponse{
			Challenge:     challengeDTO,
			UserChallenge: userChallengeDTO,
			IsCompleted:   true,
			CanComplete:   false,
		}
	}

	// Get user stats
	stats, err := uc.challengeUseCase.GetUserStats(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user stats: %w", err)
	}

	// Convert stats to DTO if needed
	var statsDTO *dto.ChallengeStatsDTO
	if stats != nil {
		statsDTO = &dto.ChallengeStatsDTO{
			UserID:          stats.UserID,
			TotalChallenges: stats.TotalChallenges,
			CompletedCount:  stats.CompletedCount,
			TotalPoints:     stats.TotalPoints,
			CurrentStreak:   stats.CurrentStreak,
			LongestStreak:   stats.LongestStreak,
		}
	}

	dashboardResponse := &dto.DashboardResponse{
		TodaysChallenges:  todaysChallenges,
		RecentlyCompleted: recentlyCompleted,
		Stats:             statsDTO,
		CurrentStreak:     statsDTO.CurrentStreak,
		TotalPoints:       statsDTO.TotalPoints,
	}

	return dashboardResponse, nil
}

// StreakUseCase handles streak-related operations
type StreakUseCase struct {
	userChallengeRepo domain.UserChallengeRepository
	statsRepo         domain.ChallengeStatsRepository
}

// NewStreakUseCase creates a new streak use case
func NewStreakUseCase(
	userChallengeRepo domain.UserChallengeRepository,
	statsRepo domain.ChallengeStatsRepository,
) *StreakUseCase {
	return &StreakUseCase{
		userChallengeRepo: userChallengeRepo,
		statsRepo:         statsRepo,
	}
}

// CalculateUserStreak calculates the current streak for a user
func (uc *StreakUseCase) CalculateUserStreak(userID string) (int, error) {
	if userID == "" {
		return 0, errors.New("user ID cannot be empty")
	}

	// Get all user challenges ordered by date (most recent first)
	userChallenges, err := uc.userChallengeRepo.GetUserChallengesByUserID(userID)
	if err != nil {
		return 0, fmt.Errorf("failed to get user challenges: %w", err)
	}

	if len(userChallenges) == 0 {
		return 0, nil
	}

	// Group challenges by date and calculate streak
	streakCount := 0
	currentDate := time.Now().Truncate(24 * time.Hour)

	// Check each day going backwards from today
	for {
		hasCompletedChallenge := false
		dateStr := currentDate.Format("2006-01-02")

		// Check if user completed any challenge on this date
		for _, uc := range userChallenges {
			challengeDate := uc.CreatedAt.Truncate(24 * time.Hour)
			if challengeDate.Format("2006-01-02") == dateStr && uc.Status == dto.StatusCompleted {
				hasCompletedChallenge = true
				break
			}
		}

		if hasCompletedChallenge {
			streakCount++
			currentDate = currentDate.AddDate(0, 0, -1)
		} else {
			break
		}
	}

	return streakCount, nil
}

// UpdateUserStreak updates the user's streak in the database
func (uc *StreakUseCase) UpdateUserStreak(userID string) error {
	if userID == "" {
		return errors.New("user ID cannot be empty")
	}

	// Calculate current streak
	currentStreak, err := uc.CalculateUserStreak(userID)
	if err != nil {
		return fmt.Errorf("failed to calculate user streak: %w", err)
	}

	// Get user stats
	stats, err := uc.statsRepo.GetUserStats(userID)
	if err != nil {
		return fmt.Errorf("failed to get user stats: %w", err)
	}

	// Update streak
	stats.CurrentStreak = currentStreak
	if currentStreak > stats.LongestStreak {
		stats.LongestStreak = currentStreak
	}

	// Save updated stats
	err = uc.statsRepo.UpdateUserStats(stats)
	if err != nil {
		return fmt.Errorf("failed to update user stats: %w", err)
	}

	return nil
}

// NotificationUseCase handles notification-related operations
type NotificationUseCase struct {
	challengeRepo     domain.ChallengeRepository
	userChallengeRepo domain.UserChallengeRepository
}

// NewNotificationUseCase creates a new notification use case
func NewNotificationUseCase(
	challengeRepo domain.ChallengeRepository,
	userChallengeRepo domain.UserChallengeRepository,
) *NotificationUseCase {
	return &NotificationUseCase{
		challengeRepo:     challengeRepo,
		userChallengeRepo: userChallengeRepo,
	}
}

// GetUsersWithPendingChallenges returns users who have pending challenges
func (uc *NotificationUseCase) GetUsersWithPendingChallenges() ([]string, error) {
	// This would need to be implemented in the repository layer
	// For now, we'll return an empty slice
	return []string{}, nil
}

// GetUserNotificationData gets data needed for user notifications
func (uc *NotificationUseCase) GetUserNotificationData(userID string) (map[string]any, error) {
	if userID == "" {
		return nil, errors.New("user ID cannot be empty")
	}

	// Get pending challenges
	pendingChallenges, err := uc.userChallengeRepo.GetPendingChallenges(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get pending challenges: %w", err)
	}

	// Get today's challenges
	todaysChallenges, err := uc.userChallengeRepo.GetTodaysUserChallenges(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get today's challenges: %w", err)
	}

	notificationData := map[string]any{
		"user_id":            userID,
		"pending_count":      len(pendingChallenges),
		"todays_count":       len(todaysChallenges),
		"pending_challenges": pendingChallenges,
		"todays_challenges":  todaysChallenges,
	}

	return notificationData, nil
}
