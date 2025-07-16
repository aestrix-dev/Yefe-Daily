package dto

type PuzzleSubmissionResult struct {
	IsCorrect      bool   `json:"isCorrect"`
	CorrectAnswer  int    `json:"correctAnswer"`
	Explanation    string `json:"explanation"`
	PointsEarned   int    `json:"pointsEarned"`
	IsFirstAttempt bool   `json:"isFirstAttempt"`
}

type DailyPuzzleResponse struct {
	Puzzle      any    `json:"puzzle"`
	IsCompleted bool   `json:"isCompleted"`
	Progress    any    `json:"progress,omitempty"`
	Date        string `json:"date"`
}

type SubmitAnswerRequest struct {
	PuzzleId       string `json:"puzzle_id" validate:"required"`
	SelectedAnswer int    `json:"selectedAnswer" validate:"required"`
}
