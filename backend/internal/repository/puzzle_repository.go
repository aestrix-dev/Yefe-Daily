package repository

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"
	"yefe_app/v1/internal/domain"
)

type puzzleRepository struct {
	puzzlesData *domain.PuzzleData
	jsonPath    string
}

func NewPuzzleRepository(jsonPath string) domain.PuzzleRepository {
	return &puzzleRepository{
		puzzlesData: &domain.PuzzleData{},
		jsonPath:    jsonPath,
	}
}

func (r *puzzleRepository) loadPuzzlesFromJSON() error {
	// Create directory if it doesn't exist
	dir := filepath.Dir(r.jsonPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create directory: %w", err)
	}

	// Read existing file
	data, err := os.ReadFile(r.jsonPath)
	if err != nil {
		return fmt.Errorf("failed to read puzzle file: %w", err)
	}

	err = json.Unmarshal(data, r.puzzlesData)
	if err != nil {
		return fmt.Errorf("failed to unmarshal puzzle data: %w", err)
	}

	return nil
}

func (r *puzzleRepository) GetAllPuzzles() ([]domain.Puzzle, error) {
	if r.puzzlesData == nil || len(r.puzzlesData.Puzzles) == 0 {
		if err := r.loadPuzzlesFromJSON(); err != nil {
			return nil, err
		}
	}
	return r.puzzlesData.Puzzles, nil
}
func (r *puzzleRepository) GetPuzzleByID(id string) (*domain.Puzzle, error) {
	puzzles, err := r.GetAllPuzzles()
	if err != nil {
		return nil, err
	}

	for _, puzzle := range puzzles {
		if puzzle.ID == id {
			return &puzzle, nil
		}
	}

	return nil, fmt.Errorf("puzzle with ID %s not found", id)
}
func (r *puzzleRepository) GetRandomPuzzle() (*domain.Puzzle, error) {
	puzzles, err := r.GetAllPuzzles()
	if err != nil {
		return nil, err
	}

	if len(puzzles) == 0 {
		return nil, fmt.Errorf("no puzzles available")
	}

	// Simple random selection based on current time
	index := int(time.Now().UnixNano()) % len(puzzles)
	return &puzzles[index], nil
}
