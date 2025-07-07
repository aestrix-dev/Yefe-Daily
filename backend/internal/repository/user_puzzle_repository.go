// repository/user_puzzle_repository.go
package repository

import (
	"database/sql"
	"fmt"
	"time"
	"yefe_app/v1/internal/domain"

	"gorm.io/gorm"
)

type userPuzzleRepository struct {
	db *gorm.DB
}

func NewUserPuzzleRepository(db *gorm.DB) domain.UserPuzzleRepository {
	return &userPuzzleRepository{
		db: db,
	}
}

func (r *userPuzzleRepository) CreateUserPuzzleProgress(progress *domain.UserPuzzleProgress) error {
	progress.CreatedAt = time.Now()
	progress.UpdatedAt = time.Now()

	if err := r.db.Create(progress).Error; err != nil {
		return fmt.Errorf("failed to create user puzzle progress: %w", err)
	}
	return nil
}

func (r *userPuzzleRepository) GetUserPuzzleProgressForDate(userID, date string) (*domain.UserPuzzleProgress, error) {
	var progress domain.UserPuzzleProgress
	err := r.db.Where("user_id = ? AND date = ?", userID, date).First(&progress).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get user puzzle progress for date: %w", err)
	}
	return &progress, nil
}

func (r *userPuzzleRepository) GetUserPuzzleProgress(userID, puzzleID string) (*domain.UserPuzzleProgress, error) {
	var progress domain.UserPuzzleProgress
	err := r.db.Where("user_id = ? AND puzzle_id = ?", userID, puzzleID).First(&progress).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get user puzzle progress: %w", err)
	}
	return &progress, nil
}

func (r *userPuzzleRepository) UpdateUserPuzzleProgress(progress *domain.UserPuzzleProgress) error {
	progress.UpdatedAt = time.Now()

	if err := r.db.Save(progress).Error; err != nil {
		return fmt.Errorf("failed to update user puzzle progress: %w", err)
	}
	return nil
}

func (r *userPuzzleRepository) GetUserPuzzleProgressByUserID(userID string) ([]domain.UserPuzzleProgress, error) {
	var progressList []domain.UserPuzzleProgress
	err := r.db.Where("user_id = ?", userID).Order("updated_at DESC").Find(&progressList).Error
	if err != nil {
		return nil, fmt.Errorf("failed to get user puzzle progress list: %w", err)
	}
	return progressList, nil
}

func (r *userPuzzleRepository) GetUserPuzzleStats(userID string) (*domain.PuzzleStats, error) {
	var stats domain.PuzzleStats

	// Get total puzzles attempted
	err := r.db.Model(&domain.UserPuzzleProgress{}).
		Where("user_id = ?", userID).
		Count(&[]int64{int64(stats.TotalPuzzles)}[0]).Error
	if err != nil {
		return nil, fmt.Errorf("failed to count total puzzles: %w", err)
	}

	// Get completed puzzles
	err = r.db.Model(&domain.UserPuzzleProgress{}).
		Where("user_id = ? AND is_completed = ?", userID, true).
		Count(&[]int64{int64(stats.CompletedPuzzles)}[0]).Error
	if err != nil {
		return nil, fmt.Errorf("failed to count completed puzzles: %w", err)
	}

	// Get correct answers
	err = r.db.Model(&domain.UserPuzzleProgress{}).
		Where("user_id = ? AND is_correct = ?", userID, true).
		Count(&[]int64{int64(stats.CorrectAnswers)}[0]).Error
	if err != nil {
		return nil, fmt.Errorf("failed to count correct answers: %w", err)
	}

	// Get total points earned
	var totalPoints sql.NullInt64
	err = r.db.Model(&domain.UserPuzzleProgress{}).
		Where("user_id = ?", userID).
		Select("SUM(points_earned)").
		Scan(&totalPoints).Error
	if err != nil {
		return nil, fmt.Errorf("failed to sum points earned: %w", err)
	}
	stats.TotalPointsEarned = int(totalPoints.Int64)

	// Calculate average accuracy
	if stats.TotalPuzzles > 0 {
		stats.AverageAccuracy = float64(stats.CorrectAnswers) / float64(stats.TotalPuzzles) * 100
	}

	// Get streak count
	streak, err := r.GetUserStreakCount(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get streak count: %w", err)
	}
	stats.Streak = streak

	return &stats, nil
}

func (r *userPuzzleRepository) HasUserCompletedDailyPuzzle(userID string) (bool, error) {
	var count int64
	today := time.Now().Format("2006-01-02") // Example: "2025-07-02"
	err := r.db.Model(&domain.UserPuzzleProgress{}).
  Where("user_id = ? AND date = ? AND is_completed = ?", userID, today, true).
		Count(&count).Error
	if err != nil {
		return false, fmt.Errorf("failed to check if user completed daily puzzle: %w", err)
	}
	return count > 0, nil
}

func (r *userPuzzleRepository) GetUserStreakCount(userID string) (int, error) {
	// Get the most recent puzzle completions ordered by completion date
	var progressList []domain.UserPuzzleProgress
	err := r.db.Where("user_id = ? AND is_completed = ? AND is_correct = ?", userID, true, true).
		Order("completed_at DESC").
		Find(&progressList).Error
	if err != nil {
		return 0, fmt.Errorf("failed to get user progress for streak calculation: %w", err)
	}

	if len(progressList) == 0 {
		return 0, nil
	}

	streak := 0
	//	yesterday := time.Now().AddDate(0, 0, -1).Format("2006-01-02")
	today := time.Now().Format("2006-01-02")

	// Simple streak calculation - consecutive days with correct answers
	streakMap := make(map[string]bool)
	for _, progress := range progressList {
		if progress.CompletedAt != nil {
			date := progress.CompletedAt.Format("2006-01-02")
			streakMap[date] = true
		}
	}

	// Check streak starting from today or yesterday
	currentDate := time.Now()
	if !streakMap[today] {
		currentDate = currentDate.AddDate(0, 0, -1)
	}

	for {
		dateStr := currentDate.Format("2006-01-02")
		if streakMap[dateStr] {
			streak++
			currentDate = currentDate.AddDate(0, 0, -1)
		} else {
			break
		}
	}

	return streak, nil
}

func (r *userPuzzleRepository) DeleteUserPuzzleProgress(userID, puzzleID string) error {
	err := r.db.Where("user_id = ? AND puzzle_id = ?", userID, puzzleID).
		Delete(&domain.UserPuzzleProgress{}).Error
	if err != nil {
		return fmt.Errorf("failed to delete user puzzle progress: %w", err)
	}
	return nil
}
