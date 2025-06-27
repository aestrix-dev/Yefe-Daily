package domain

import (
	"context"
	"time"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/types"
)

// JournalEntry represents a journal entry
type JournalEntry struct {
	ID        string     `json:"id"`
	UserID    string     `json:"user_id"`
	Title     string     `json:"title"`
	Content   string     `json:"content"`
	Type      string     `json:"type"`
	Tags      types.Tags `json:"tags"`
	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`
	User      User       `json:"-"`
}

// JournalRepository defines the interface for journal operations
type JournalRepository interface {
	Create(ctx context.Context, entry *JournalEntry) error
	GetByID(ctx context.Context, id string) (*JournalEntry, error)
	GetByUserID(ctx context.Context, userID string, limit, offset int) ([]*JournalEntry, error)
	GetByUserIDAndType(ctx context.Context, userID, entryType string, limit, offset int) ([]*JournalEntry, error)
	GetByUserIDAndDateRange(ctx context.Context, userID string, startDate, endDate time.Time) ([]*JournalEntry, error)
	GetByUserIDAndTags(ctx context.Context, userID string, tags []string, limit, offset int) ([]*JournalEntry, error)
	Update(ctx context.Context, entry *JournalEntry) error
	Delete(ctx context.Context, id string) error
	Count(ctx context.Context, userID string) (int64, error)
	CountByType(ctx context.Context, userID, entryType string) (int64, error)
	SearchByContent(ctx context.Context, userID, query string, limit, offset int) ([]*JournalEntry, error)
	GetTodayEntry(ctx context.Context, userID, entryType string) (*JournalEntry, error)
}

// JournalUseCase defines the interface for journal business logic
type JournalUseCase interface {
	CreateEntry(ctx context.Context, userID string, req dto.CreateJournalEntryRequest) (*dto.JournalEntryResponse, error)
	GetEntry(ctx context.Context, userID, entryID string) (*dto.JournalEntryResponse, error)
	GetEntries(ctx context.Context, userID string, filter dto.JournalEntryFilter) (*dto.JournalEntriesResponse, error)
	UpdateEntry(ctx context.Context, userID, entryID string, req dto.UpdateJournalEntryRequest) (*dto.JournalEntryResponse, error)
	DeleteEntry(ctx context.Context, userID, entryID string) error
	GetTodayEntry(ctx context.Context, userID, entryType string) (*dto.TodayEntryResponse, error)
	GetStats(ctx context.Context, userID string) (*dto.JournalStatsResponse, error)
	SearchEntries(ctx context.Context, userID, query string, limit, offset int) (*dto.JournalEntriesResponse, error)
}
