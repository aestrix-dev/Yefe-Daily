package usecase

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/pkg/cache"
	"yefe_app/v1/pkg/logger"
)

type dailyReflectionUseCase struct {
	dailyReflections []domain.DailyReflection
	cache            *cache.Cache
	jsonPath         string
}

// NewChallengeRepository creates a new instance of challengeRepositoryImpl
func NewDailyReflectionUseCase(path string, cache *cache.Cache) (domain.DailyReflectionUseCase, error) {
	repo := &dailyReflectionUseCase{jsonPath: path, cache: cache}
	if err := repo.loadReflectionsFromJSON(); err != nil {
		return nil, err
	}
	return repo, nil
}
func (r *dailyReflectionUseCase) loadReflectionsFromJSON() error {
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

	err = json.Unmarshal(data, &r.dailyReflections)
	if err != nil {
		return fmt.Errorf("failed to unmarshal challenges data: %w", err)
	}

	return nil
}
func (r *dailyReflectionUseCase) GetRandomDailyReflection() domain.DailyReflection {
	// Simple random selection based on current time
	index := int(time.Now().UnixNano()) % len(r.dailyReflections)
	return r.dailyReflections[index]
}

func (r *dailyReflectionUseCase) GetTodaysDailyReflection(ctx context.Context) (domain.DailyReflection, error) {
	var dailyReflection domain.DailyReflection
	reflection, ok := r.cache.GetWithContext(ctx, "daily-reflection")

	if !ok {
		logger.Log.Warning("No reflection found")
		return domain.DailyReflection{}, fmt.Errorf("Reflection not found")
	}

	dailyReflection = reflection.(domain.DailyReflection)
	return dailyReflection, nil
}
