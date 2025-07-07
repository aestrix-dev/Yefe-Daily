package usecase

import (
	"fmt"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
)

type puzzleUseCase struct {
	puzzleRepo     domain.PuzzleRepository
	userPuzzleRepo domain.UserPuzzleRepository
}

func NewPuzzleUseCase(
	puzzleRepo domain.PuzzleRepository,
	userPuzzleRepo domain.UserPuzzleRepository,
) domain.PuzzleUseCase {
	return &puzzleUseCase{
		puzzleRepo:     puzzleRepo,
		userPuzzleRepo: userPuzzleRepo,
	}
}

func (uc *puzzleUseCase) GetAllPuzzles() ([]domain.Puzzle, error) {
	return uc.puzzleRepo.GetAllPuzzles()
}

func (uc *puzzleUseCase) GetRandomPuzzle() (*domain.Puzzle, error) {
	return uc.puzzleRepo.GetRandomPuzzle()
}

func (uc *puzzleUseCase) SubmitPuzzleAnswer(userID, puzzleID string, selectedAnswer int) (*dto.PuzzleSubmissionResult, error) {
	// Get the puzzle
	puzzle, err := uc.puzzleRepo.GetPuzzleByID(puzzleID)
	if err != nil {
		return nil, fmt.Errorf("failed to get puzzle: %w", err)
	}

	// Validate selected answer
	if selectedAnswer < 0 || selectedAnswer >= len(puzzle.Options) {
		return nil, fmt.Errorf("invalid answer selection")
	}

	// Check if user has already attempted this puzzle
	existingProgress, err := uc.userPuzzleRepo.GetUserPuzzleProgress(userID, puzzleID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user progress: %w", err)
	}

	isCorrect := selectedAnswer == puzzle.CorrectAnswer
	isFirstAttempt := existingProgress == nil
	pointsEarned := 0

	// Calculate points (only for correct answers on first attempt)
	if isCorrect && isFirstAttempt {
		pointsEarned = puzzle.Points
	}

	now := time.Now()

	if existingProgress == nil {
		// Create new progress record
		progress := &domain.UserPuzzleProgress{
			ID:             fmt.Sprintf("%s_%s_%d", userID, puzzleID, now.Unix()),
			UserID:         userID,
			PuzzleID:       puzzleID,
			IsCompleted:    true,
			SelectedAnswer: &selectedAnswer,
			IsCorrect:      &isCorrect,
			CompletedAt:    &now,
			AttemptsCount:  1,
			PointsEarned:   pointsEarned,
		}

		err = uc.userPuzzleRepo.CreateUserPuzzleProgress(progress)
		if err != nil {
			return nil, fmt.Errorf("failed to create user progress: %w", err)
		}
	} else {
		// Update existing progress
		existingProgress.IsCompleted = true
		existingProgress.SelectedAnswer = &selectedAnswer
		existingProgress.IsCorrect = &isCorrect
		existingProgress.CompletedAt = &now
		existingProgress.AttemptsCount++

		// Only award points if this is the first correct answer
		if isCorrect && (existingProgress.IsCorrect == nil || !*existingProgress.IsCorrect) {

			existingProgress.PointsEarned = puzzle.Points
			pointsEarned = puzzle.Points
		}

		err = uc.userPuzzleRepo.UpdateUserPuzzleProgress(existingProgress)
		if err != nil {
			return nil, fmt.Errorf("failed to update user progress: %w", err)
		}
	}

	return &dto.PuzzleSubmissionResult{
		IsCorrect:      isCorrect,
		CorrectAnswer:  puzzle.CorrectAnswer,
		Explanation:    puzzle.Explanation,
		PointsEarned:   pointsEarned,
		IsFirstAttempt: isFirstAttempt,
	}, nil
}

func (uc *puzzleUseCase) GetUserPuzzleProgress(userID, puzzleID string) (*domain.UserPuzzleProgress, error) {
	return uc.userPuzzleRepo.GetUserPuzzleProgress(userID, puzzleID)
}

func (uc *puzzleUseCase) GetUserPuzzleStats(userID string) (*domain.PuzzleStats, error) {
	return uc.userPuzzleRepo.GetUserPuzzleStats(userID)
}

func (uc *puzzleUseCase) GetUserCompletedPuzzles(userID string) ([]domain.UserPuzzleProgress, error) {
	allProgress, err := uc.userPuzzleRepo.GetUserPuzzleProgressByUserID(userID)
	if err != nil {
		return nil, err
	}

	var completedPuzzles []domain.UserPuzzleProgress
	for _, progress := range allProgress {
		if progress.IsCompleted {
			completedPuzzles = append(completedPuzzles, progress)
		}
	}

	return completedPuzzles, nil
}

func (uc *puzzleUseCase) ResetUserPuzzleProgress(userID, puzzleID string) error {
	return uc.userPuzzleRepo.DeleteUserPuzzleProgress(userID, puzzleID)
}
