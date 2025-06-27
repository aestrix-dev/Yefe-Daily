package dto

import (
	"time"
)

// CreateJournalEntryRequest represents the request to create a journal entry
type CreateJournalEntryRequest struct {
	Title   string   `json:"title" validate:"max=200"`
	Content string   `json:"content" validate:"required,min=1,max=10000"`
	Type    string   `json:"type" validate:"required,oneof=morning evening wisdom_note"`
	Tags    []string `json:"tags" validate:"dive,max=50"`
}

// UpdateJournalEntryRequest represents the request to update a journal entry
type UpdateJournalEntryRequest struct {
	Title   *string  `json:"title,omitempty" validate:"omitempty,max=200"`
	Content *string  `json:"content,omitempty" validate:"omitempty,min=1,max=10000"`
	Tags    []string `json:"tags,omitempty" validate:"dive,max=50"`
}

// JournalEntryResponse represents the response for a journal entry
type JournalEntryResponse struct {
	ID        string    `json:"id"`
	Title     string    `json:"title"`
	Content   string    `json:"content"`
	Type      string    `json:"type"`
	Tags      []string  `json:"tags"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// JournalEntriesResponse represents the response for multiple journal entries
type JournalEntriesResponse struct {
	Entries    []JournalEntryResponse `json:"entries"`
	Total      int64                  `json:"total"`
	Limit      int                    `json:"limit"`
	Offset     int                    `json:"offset"`
	HasMore    bool                   `json:"has_more"`
	TotalPages int                    `json:"total_pages"`
}

// GetJournalEntriesRequest represents the request parameters for getting journal entries
type GetJournalEntriesRequest struct {
	Type      string   `json:"type,omitempty" validate:"omitempty,oneof=morning evening wisdom_note"`
	Tags      []string `json:"tags,omitempty" validate:"dive,max=50"`
	Search    string   `json:"search,omitempty" validate:"omitempty,max=100"`
	StartDate *string  `json:"start_date,omitempty" validate:"omitempty,datetime=2006-01-02"`
	EndDate   *string  `json:"end_date,omitempty" validate:"omitempty,datetime=2006-01-02"`
	Limit     int      `json:"limit" validate:"min=1,max=100"`
	Offset    int      `json:"offset" validate:"min=0"`
}

// TodayEntryResponse represents the response for today's entry
type TodayEntryResponse struct {
	Entry  *JournalEntryResponse `json:"entry"`
	Exists bool                  `json:"exists"`
}

// JournalStatsResponse represents journal statistics
type JournalStatsResponse struct {
	TotalEntries    int64                  `json:"total_entries"`
	EntriesByType   map[string]int64       `json:"entries_by_type"`
	CurrentStreak   int                    `json:"current_streak"`
	LongestStreak   int                    `json:"longest_streak"`
	TagsUsage       map[string]int         `json:"tags_usage"`
	RecentActivity  []JournalEntryResponse `json:"recent_activity"`
	MonthlyProgress []MonthlyProgressEntry `json:"monthly_progress"`
}

// MonthlyProgressEntry represents progress for a specific month
type MonthlyProgressEntry struct {
	Month   string `json:"month"` // Format: "2024-01"
	Count   int64  `json:"count"`
	Target  int    `json:"target"`  // Expected entries for the month
	Percent int    `json:"percent"` // Percentage of target achieved
}

// JournalEntryFilter represents filtering options for journal entries
type JournalEntryFilter struct {
	UserID    string
	Type      string
	Tags      []string
	Search    string
	StartDate *time.Time
	EndDate   *time.Time
	Limit     int
	Offset    int
}

// ErrorResponse represents an error response
type ErrorResponse struct {
	Error   string            `json:"error"`
	Message string            `json:"message"`
	Code    string            `json:"code,omitempty"`
	Details map[string]string `json:"details,omitempty"`
}

// SuccessResponse represents a success response
type SuccessResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// ValidationError represents validation errors
type ValidationError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
	Value   string `json:"value,omitempty"`
}

// ValidationErrorResponse represents validation error response
type ValidationErrorResponse struct {
	Error   string            `json:"error"`
	Message string            `json:"message"`
	Errors  []ValidationError `json:"errors"`
}
