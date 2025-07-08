package repository

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/internal/infrastructure/db/models"
	"yefe_app/v1/pkg/utils"

	"gorm.io/gorm"
)

// challengeRepositoryImpl implements the ChallengeRepository interface
type challengeRepositoryImpl struct {
	db             *gorm.DB
	challengesData domain.ChallengesData
	jsonPath       string
}

// NewChallengeRepository creates a new instance of challengeRepositoryImpl
func NewChallengeRepository(db *gorm.DB, challengesPath string) (domain.ChallengeRepository, error) {
	repo := &challengeRepositoryImpl{db: db, jsonPath: challengesPath}
	if err := repo.loadChallengesFromJSON(); err != nil {
		return nil, err
	}
	return repo, nil
}

func (r *challengeRepositoryImpl) loadChallengesFromJSON() error {
	// Create directory if it doesn't exist
	dir := filepath.Dir(r.jsonPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create directory: %w", err)
	}

	// Read existing file
	data, err := os.ReadFile(r.jsonPath)
	if err != nil {
		return fmt.Errorf("failed to read challenges file: %w", err)
	}

	err = json.Unmarshal(data, &r.challengesData)
	if err != nil {
		return fmt.Errorf("failed to unmarshal challenges data: %w", err)
	}

	return nil
}

func (r *challengeRepositoryImpl) CreateChallenge(challenge *domain.Challenge) error {
	modelChallenge := &models.Challenge{
		ID:          challenge.ID,
		Title:       challenge.Title,
		Description: challenge.Description,
		Type:        challenge.Type,
		Points:      challenge.Points,
		IsActive:    true,
	}

	if err := r.db.Create(modelChallenge).Error; err != nil {
		return err
	}
	return nil
}

func (r *challengeRepositoryImpl) DeleteChallenge(id string) error {
	return r.db.Where("id = ?", id).Delete(&models.Challenge{}).Error
}

// GetChallengeByID retrieves a challenge by ID
func (r *challengeRepositoryImpl) GetChallengeByID(id string) (domain.Challenge, error) {
	var dbchallenge models.Challenge
	var challenge domain.Challenge
	if err := r.db.Where("id = ? AND is_active = ?", id, true).First(&dbchallenge).Error; err != nil {
		return domain.Challenge{}, err
	}
	err := utils.TypeConverter(dbchallenge, &challenge)
	if err != nil {
		return domain.Challenge{}, err
	}

	return challenge, nil
}

// GetChallengesByDate retrieves challenges for a specific date
func (r *challengeRepositoryImpl) GetChallengeByDate(date time.Time) (domain.Challenge, error) {
	var dbchallenge models.Challenge
	var challenge domain.Challenge
	if err := r.db.Where("date = ? AND is_active = ?", date.Format("2006-01-02"), true).Find(&dbchallenge).Error; err != nil {
		return domain.Challenge{}, err
	}

	err := utils.TypeConverter(dbchallenge, &challenge)
	if err != nil {
		return domain.Challenge{}, err
	}

	return challenge, nil
}

// GetTodaysChallenges retrieves today's challenges
func (r *challengeRepositoryImpl) GetTodaysChallenge() (domain.Challenge, error) {
	today := time.Now().Format("2006-01-02")
	var dbchallenge models.Challenge
	var challenge domain.Challenge
	if err := r.db.Where("date = ? AND is_active = ?", today, true).Find(&dbchallenge).Error; err != nil {
		return domain.Challenge{}, err
	}
	err := utils.TypeConverter(dbchallenge, &challenge)
	if err != nil {
		return domain.Challenge{}, err
	}

	return challenge, nil
}

func (r *challengeRepositoryImpl) GetRandomChallange() domain.Challenge {
	// Simple random selection based on current time
	index := int(time.Now().UnixNano()) % len(r.challengesData.Challenges)
	return r.challengesData.Challenges[index]
}

// userChallengeRepositoryImpl implements the UserChallengeRepository interface
type userChallengeRepositoryImpl struct {
	db *gorm.DB
}

// NewUserChallengeRepository creates a new instance of userChallengeRepositoryImpl
func NewUserChallengeRepository(db *gorm.DB) domain.UserChallengeRepository {
	return &userChallengeRepositoryImpl{db: db}
}

// CreateUserChallenge creates a new user challenge
func (r *userChallengeRepositoryImpl) CreateUserChallenge(userChallenge domain.UserChallenge) error {
	modelUserChallenge := &models.UserChallenge{
		ID:          userChallenge.ID,
		UserID:      userChallenge.UserID,
		ChallengeID: userChallenge.ChallengeID,
		Status:      userChallenge.Status,
		CompletedAt: userChallenge.CompletedAt,
		CreatedAt:   userChallenge.CreatedAt,
		UpdatedAt:   userChallenge.UpdatedAt,
	}

	if err := r.db.Create(modelUserChallenge).Error; err != nil {
		return err
	}

	// Update the domain object with any auto-generated values
	userChallenge.CreatedAt = modelUserChallenge.CreatedAt
	userChallenge.UpdatedAt = modelUserChallenge.UpdatedAt
	return nil
}

func (r *userChallengeRepositoryImpl) GetTodaysUserChallenge(userID string) (domain.UserChallenge, error) {
	today := time.Now().Format("2006-01-02")
	var dbuserChallenge models.UserChallenge
	var userChallenge domain.UserChallenge
	if err := r.db.Preload("Challenge").
		Joins("JOIN challenges ON challenges.id = user_challenges.challenge_id").
		Where("user_challenges.user_id = ? AND challenges.date = ?", userID, today).
		Find(&dbuserChallenge).Error; err != nil {
		return domain.UserChallenge{}, err
	}
	err := utils.TypeConverter(dbuserChallenge, &userChallenge)
	if err != nil {
		return domain.UserChallenge{}, err
	}

	return userChallenge, nil
}

// GetUserChallengeByID retrieves a user challenge by ID
func (r *userChallengeRepositoryImpl) GetUserChallengeByID(id string) (domain.UserChallenge, error) {
	var dbuserChallenges models.UserChallenge
	var userChallenges domain.UserChallenge
	if err := r.db.Preload("Challenge").Where("id = ?", id).First(&dbuserChallenges).Error; err != nil {
		return domain.UserChallenge{}, err
	}

	err := utils.TypeConverter(dbuserChallenges, &userChallenges)
	if err != nil {
		return domain.UserChallenge{}, err
	}
	return userChallenges, nil
}

// GetUserChallengesByUserID retrieves all user challenges for a specific user
func (r *userChallengeRepositoryImpl) GetUserChallengesByUserID(userID string) ([]domain.UserChallenge, error) {
	var dbuserChallenges []models.UserChallenge
	var userChallenges []domain.UserChallenge
	if err := r.db.Preload("Challenge").Where("user_id = ?", userID).
		Order("created_at DESC").Find(&userChallenges).Error; err != nil {
		return nil, err
	}

	err := utils.TypeConverter(dbuserChallenges, &userChallenges)
	if err != nil {
		return nil, err
	}
	return userChallenges, nil
}

// GetUserChallengesByDate retrieves user challenges for a specific date
func (r *userChallengeRepositoryImpl) GetUserChallengesByDate(userID string, date time.Time) ([]domain.UserChallenge, error) {
	var dbuserChallenges []models.UserChallenge
	var userChallenges []domain.UserChallenge
	if err := r.db.Preload("Challenge").
		Joins("JOIN challenges ON challenges.id = user_challenges.challenge_id").
		Where("user_challenges.user_id = ? AND challenges.date = ?", userID, date.Format("2006-01-02")).
		Find(&dbuserChallenges).Error; err != nil {
		return nil, err
	}

	err := utils.TypeConverter(dbuserChallenges, &userChallenges)
	if err != nil {
		return nil, err
	}
	return userChallenges, nil
}

// UpdateUserChallenge updates an existing user challenge
func (r *userChallengeRepositoryImpl) UpdateUserChallenge(userChallenge domain.UserChallenge) error {
	modelUserChallenge := &models.UserChallenge{
		ID:          userChallenge.ID,
		UserID:      userChallenge.UserID,
		ChallengeID: userChallenge.ChallengeID,
		Status:      userChallenge.Status,
		CompletedAt: userChallenge.CompletedAt,
		UpdatedAt:   time.Now(),
	}

	if err := r.db.Model(modelUserChallenge).Where("id = ?", userChallenge.ID).Updates(modelUserChallenge).Error; err != nil {
		return err
	}

	userChallenge.UpdatedAt = modelUserChallenge.UpdatedAt
	return nil
}

// GetUserChallengesByStatus retrieves user challenges by status
func (r *userChallengeRepositoryImpl) GetUserChallengesByStatus(userID string, status string) ([]domain.UserChallenge, error) {
	var dbuserChallenges []models.UserChallenge
	var userChallenges []domain.UserChallenge
	if err := r.db.Preload("Challenge").Where("user_id = ? AND status = ?", userID, status).
		Order("created_at DESC").Find(&dbuserChallenges).Error; err != nil {
		return nil, err
	}

	err := utils.TypeConverter(dbuserChallenges, &userChallenges)
	if err != nil {
		return nil, err
	}
	return userChallenges, nil
}

// GetCompletedChallenges retrieves completed challenges for a user
func (r *userChallengeRepositoryImpl) GetCompletedChallenges(userID string, limit int) ([]domain.UserChallenge, error) {
	var dbuserChallenges []models.UserChallenge
	var userChallenges []domain.UserChallenge
	query := r.db.Preload("Challenge").Where("user_id = ? AND status = ?", userID, dto.StatusCompleted).
		Order("completed_at DESC")

	if limit > 0 {
		query = query.Limit(limit)
	}

	if err := query.Find(&dbuserChallenges).Error; err != nil {
		return nil, err
	}

	err := utils.TypeConverter(dbuserChallenges, &userChallenges)
	if err != nil {
		return nil, err
	}
	return userChallenges, nil
}

// GetPendingChallenges retrieves pending challenges for a user
func (r *userChallengeRepositoryImpl) GetPendingChallenges(userID string) ([]domain.UserChallenge, error) {
	var dbuserChallenges []models.UserChallenge
	var userChallenge []domain.UserChallenge
	if err := r.db.Preload("Challenge").Where("user_id = ? AND status = ?", userID, dto.StatusPending).
		Order("created_at ASC").Find(&dbuserChallenges).Error; err != nil {
		return nil, err
	}

	err := utils.TypeConverter(dbuserChallenges, &userChallenge)
	if err != nil {
		return nil, err
	}
	return userChallenge, nil
}

// ChallengeStatsRepositoryImpl implements the ChallengeStatsRepository interface
type ChallengeStatsRepositoryImpl struct {
	db *gorm.DB
}

// NewChallengeStatsRepository creates a new instance of ChallengeStatsRepositoryImpl
func NewChallengeStatsRepository(db *gorm.DB) domain.ChallengeStatsRepository {
	return &ChallengeStatsRepositoryImpl{db: db}
}

// GetUserStats retrieves user statistics
func (r *ChallengeStatsRepositoryImpl) GetUserStats(userID string) (domain.ChallengeStats, error) {
	var dbstats models.ChallengeStats
	var stats domain.ChallengeStats
	if err := r.db.Where("user_id = ?", userID).First(&dbstats).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			// Create initial stats if not found
			dbstats = models.ChallengeStats{
				UserID:          userID,
				TotalChallenges: 0,
				CompletedCount:  0,
				TotalPoints:     0,
				CurrentStreak:   0,
				LongestStreak:   0,
			}
			if err := r.db.Create(&dbstats).Error; err != nil {
				return domain.ChallengeStats{}, err
			}
		} else {
			return domain.ChallengeStats{}, err
		}
	}
	err := utils.TypeConverter(dbstats, &stats)
	if err != nil {
		return domain.ChallengeStats{}, err
	}
	return stats, nil
}

// UpdateUserStats updates user statistics
func (r *ChallengeStatsRepositoryImpl) UpdateUserStats(userId string, points int) error {

	stats, err := r.GetUserStats(userId)
	if err != nil {
		return err
	}
	stats.TotalPoints += points
	stats.TotalChallenges += 1

	if err := r.db.Model(stats).Where("user_id = ?", stats.UserID).Updates(stats).Error; err != nil {
		return err
	}

	return nil
}

// GetLeaderboard retrieves the leaderboard
func (r *ChallengeStatsRepositoryImpl) GetLeaderboard(limit int) ([]domain.ChallengeStats, error) {
	var dbstats []models.ChallengeStats
	var stats []domain.ChallengeStats
	query := r.db.Preload("User").Order("total_points DESC, current_streak DESC")

	if limit > 0 {
		query = query.Limit(limit)
	}

	if err := query.Find(&dbstats).Error; err != nil {
		return nil, err
	}
	err := utils.TypeConverter(dbstats, &stats)
	if err != nil {
		return nil, err
	}
	return stats, nil

}
