package usecase

import (
	"errors"
	"fmt"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/utils"
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

func (c *ChallengeUseCaseImpl) GetUserStats(userId string) (domain.ChallengeStats, error) {
	if userId == "" {
		return domain.ChallengeStats{}, errors.New("UserID cannnot be empty")
	}

	return c.challengeStatsRepo.GetUserStats(userId)
}

// AssignChallengeToUser assigns all challenges for a specific date to a user
func (c *ChallengeUseCaseImpl) AssignChallengeToUser(userID string) error {
	if userID == "" {
		return errors.New("user ID cannot be empty")
	}
	challenge, err := c.GetTodaysChallenges()
	if err != nil {
		return fmt.Errorf("Failed to get challenge %w", err)
	}

	// Assign challenges that don't already exist
	userChallenge := domain.UserChallenge{
		ID:          utils.GenerateID(),
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
func (c *ChallengeUseCaseImpl) GetUserChallengeForToday(userID string) (domain.UserChallenge, error) {
	if userID == "" {
		return domain.UserChallenge{}, errors.New("user ID cannot be empty")
	}

	userChallenge, err := c.userChallengeRepo.GetTodaysUserChallenge(userID)
	if userChallenge.ChallengeID != "" {
		return userChallenge, nil
	}
	if err := c.AssignChallengeToUser(userID); err != nil {
		return domain.UserChallenge{}, err
	}
	userChallenge, err = c.userChallengeRepo.GetTodaysUserChallenge(userID)
	if err != nil {
		return domain.UserChallenge{}, err
	}
	return userChallenge, nil
}

func (c *ChallengeUseCaseImpl) GetChallengeByID(challengeID string) (domain.Challenge, error) {
	return c.challengeRepo.GetChallengeByID(challengeID)
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
		return domain.ErrInvalidRequest
	}
	if challengeID == "" {
		return domain.ErrInvalidRequest
	}

	challenge, err := c.challengeRepo.GetTodaysChallenge()
	if err != nil {
		return err
	}

	// Get the challenge to get points
	userChallenge, err := c.userChallengeRepo.GetUserChallengeByID(challengeID, userID)
	if err != nil {
		return fmt.Errorf("error getting challenge: %w", err)
	}

	if challenge.ID != userChallenge.ChallengeID {
		return domain.ErrNotTodaysChallenge
	}
	if userChallenge.Status == dto.StatusCompleted {
		return domain.ErrChallengeAlreadyCompleted
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
