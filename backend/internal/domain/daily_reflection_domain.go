package domain

import "context"

type DailyReflection struct {
	ID                int8   `json:"id"`
	Passage           string `json:"passage"`
	Reference         string `json:"reference"`
	DeeperRreflection string `json:"deeper_reflection"`
}

type DailyReflectionUseCase interface {
	GetRandomDailyReflection() DailyReflection
	GetTodaysDailyReflection(ctx context.Context) (DailyReflection, error)
}
