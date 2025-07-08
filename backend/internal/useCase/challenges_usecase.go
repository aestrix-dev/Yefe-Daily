package usecase

import (
	"errors"
	"fmt"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"

	"github.com/google/uuid"
)

// ChallengeUseCaseImpl implements the ChallengeUseCase interface
type ChallengeUseCaseImpl struct {
	challengeRepo      domain.ChallengeRepository
	userChallengeRepo  domain.UserChallengeRepository
	challengeStatsRepo domain.ChallengeStatsRepository
}

// NewChallengeUseCase creates a new instance of ChallengeUseCaseImpl
func NewChallengeUseCase(
	challengeRepo domain.ChallengeRepository,
	userChallengeRepo domain.UserChallengeRepository,
	challengeStatsRepo domain.ChallengeStatsRepository,
) domain.ChallengeUseCase {
	return &ChallengeUseCaseImpl{
		challengeRepo:      challengeRepo,
		userChallengeRepo:  userChallengeRepo,
		challengeStatsRepo: challengeStatsRepo,
	}
}

// CreateDailyChallenge creates a new daily challenge
func (c *ChallengeUseCaseImpl) CreateDailyChallenge(challenge domain.Challenge) (domain.Challenge, error) {

	if err := c.challengeRepo.CreateChallenge(&challenge); err != nil {
		return domain.Challenge{}, fmt.Errorf("error creating challenge: %w", err)
	}

	return challenge, nil
}

// GetTodaysChallenges retrieves all challenges for today
func (c *ChallengeUseCaseImpl) GetTodaysChallenges() (domain.Challenge, error) {
	return c.challengeRepo.GetTodaysChallenge()
}

// GetChallengesByDate retrieves challenges for a specific date
func (c *ChallengeUseCaseImpl) GetChallengeByDate(date time.Time) (domain.Challenge, error) {
	return c.challengeRepo.GetChallengeByDate(date)
}

func (c *ChallengeUseCaseImpl) GetUserChallengeForToday(userId string) (domain.UserChallenge, error) {
	if userId == "" {
		return domain.UserChallenge{}, errors.New("UserID cannnot be empty")
	}

	return c.userChallengeRepo.GetTodaysUserChallenge(userId)
}

func (c *ChallengeUseCaseImpl) GetUserStats(userId string) (domain.ChallengeStats, error) {
	if userId == "" {
		return domain.ChallengeStats{}, errors.New("UserID cannnot be empty")
	}

	return c.challengeStatsRepo.GetUserStats(userId)
}

// AssignChallengeToUser assigns all challenges for a specific date to a user
func (c *ChallengeUseCaseImpl) AssignChallengeToUser(userID string, date time.Time) error {
	if userID == "" {
		return errors.New("user ID cannot be empty")
	}

	// Get challenges for the date
	challenge, err := c.challengeRepo.GetChallengeByDate(date)
	if err != nil {
		return fmt.Errorf("error getting challenges for date: %w", err)
	}

	// Check if user already has challenges assigned for this date
	existingUserChallenges, err := c.userChallengeRepo.GetUserChallengesByDate(userID, date)
	if err != nil {
		return fmt.Errorf("error checking existing user challenges: %w", err)
	}

	// Create a map of existing challenge IDs for quick lookup
	existingChallengeIDs := make(map[string]bool)
	for _, uc := range existingUserChallenges {
		existingChallengeIDs[uc.ChallengeID] = true
	}

	// Assign challenges that don't already exist
	userChallenge := domain.UserChallenge{
		ID:          uuid.New().String(),
		UserID:      userID,
		ChallengeID: challenge.ID,
		Status:      dto.StatusPending,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	if err := c.userChallengeRepo.CreateUserChallenge(userChallenge); err != nil {
		return fmt.Errorf("error creating user challenge: %w", err)
	}

	return nil
}

// GetUserChallengesForToday retrieves user's challenges for today
func (c *ChallengeUseCaseImpl) GetUserChallengesForToday(userID string) (domain.UserChallenge, error) {
	if userID == "" {
		return domain.UserChallenge{}, errors.New("user ID cannot be empty")
	}

	// First, ensure challenges are assigned for today
	today := time.Now().Truncate(24 * time.Hour)
	if err := c.AssignChallengeToUser(userID, today); err != nil {
		return domain.UserChallenge{}, fmt.Errorf("error assigning today's challenges: %w", err)
	}

	return c.userChallengeRepo.GetTodaysUserChallenge(userID)
}

// GetUserChallengeHistory retrieves user's challenge history
func (c *ChallengeUseCaseImpl) GetUserChallengeHistory(userID string, limit int) ([]domain.UserChallenge, error) {
	if userID == "" {
		return nil, errors.New("user ID cannot be empty")
	}
	if limit <= 0 {
		limit = 50 // Default limit
	}

	return c.userChallengeRepo.GetCompletedChallenges(userID, limit)
}

// CompleteChallenge marks a challenge as completed for a user
func (c *ChallengeUseCaseImpl) CompleteChallenge(userID, challengeID string) error {
	if userID == "" {
		return errors.New("user ID cannot be empty")
	}
	if challengeID == "" {
		return errors.New("challenge ID cannot be empty")
	}

	// Get the user challenge
	challenges, err := c.userChallengeRepo.GetUserChallengesByUserID(userID)
	if err != nil {
		return fmt.Errorf("error getting user challenges: %w", err)
	}

	var userChallenge domain.UserChallenge
	for _, uc_ := range challenges {
		if uc_.ChallengeID == challengeID {
			userChallenge = uc_
			break
		}
	}

	if challenges == nil {
		return errors.New("user challenge not found")
	}

	if userChallenge.Status == dto.StatusCompleted {
		return errors.New("challenge is already completed")
	}

	// Get the challenge to get points
	challenge, err := c.challengeRepo.GetChallengeByID(challengeID)
	if err != nil {
		return fmt.Errorf("error getting challenge: %w", err)
	}

	// Update user challenge status
	completedAt := time.Now()
	userChallenge.Status = dto.StatusCompleted
	userChallenge.CompletedAt = &completedAt
	userChallenge.UpdatedAt = time.Now()

	if err := c.userChallengeRepo.UpdateUserChallenge(userChallenge); err != nil {
		return fmt.Errorf("error updating user challenge: %w", err)
	}

	// Update user stats
	if err := c.challengeStatsRepo.UpdateUserStats(userID, challenge.Points); err != nil {
		return fmt.Errorf("error updating user stats: %w", err)
	}

	return nil
}

func (c *ChallengeUseCaseImpl) GetLeaderboard(limit int) ([]domain.ChallengeStats, error) {
	return c.challengeStatsRepo.GetLeaderboard(limit)
}
