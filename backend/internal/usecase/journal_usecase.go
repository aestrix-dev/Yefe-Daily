package usecase

import (
	"context"
	"fmt"
	"math"
	"sort"
	"strings"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/logger"
	"yefe_app/v1/pkg/utils"
)

type journalUseCase struct {
	journalRepo domain.JournalRepository
	userRepo    domain.UserRepository
}

// NewJournalUseCase creates a new journal use case
func NewJournalUseCase(journalRepo domain.JournalRepository, userRepo domain.UserRepository) domain.JournalUseCase {
	return &journalUseCase{
		journalRepo: journalRepo,
		userRepo:    userRepo,
	}
}

// CreateEntry creates a new journal entry
func (uc *journalUseCase) CreateEntry(ctx context.Context, userID string, req dto.CreateJournalEntryRequest) (*dto.JournalEntryResponse, error) {
	var res dto.JournalEntryResponse
	// Validate user exists
	if _, err := uc.userRepo.GetByID(ctx, userID); err != nil {
		return nil, domain.ErrUnauthorized
	}

	// Validate entry type
	if !utils.IsValidEntryType(req.Type) {
		return nil, domain.ErrInvalidEntryType
	}

	// Validate content
	if strings.TrimSpace(req.Content) == "" {
		return nil, domain.ErrEmptyContent
	}

	// Create entry
	entry := &domain.JournalEntry{
		ID:        utils.GenerateID(),
		UserID:    userID,
		Content:   strings.TrimSpace(req.Content),
		Type:      req.Type,
		Tags:      sanitizeTags(req.Tags),
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	if err := uc.journalRepo.Create(ctx, entry); err != nil {
		logger.Log.WithError(err).Error("failed to create journal entry")
		return nil, fmt.Errorf("failed to create journal entry: %w", err)
	}

	if err := utils.TypeConverter(entry, &res); err != nil {

		return nil, fmt.Errorf("failed to create journal entry: %w", err)
	}
	return &res, nil

}

// GetEntry retrieves a specific journal entry
func (uc *journalUseCase) GetEntry(ctx context.Context, userID, entryID string) (*dto.JournalEntryResponse, error) {
	var res dto.JournalEntryResponse
	// Validate user exists
	entry, err := uc.journalRepo.GetByID(ctx, entryID)
	if err != nil {
		return nil, domain.ErrEntryNotFound
	}

	if entry.UserID != userID {
		return nil, domain.ErrUnauthorized
	}

	if err := utils.TypeConverter(entry, &res); err != nil {

		return nil, fmt.Errorf("failed to create journal entry: %w", err)
	}
	return &res, nil
}

// GetEntries retrieves journal entries with filtering and pagination
func (uc *journalUseCase) GetEntries(ctx context.Context, userID string, filter dto.JournalEntryFilter) (*dto.JournalEntriesResponse, error) {
	// Set default values
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}

	filter.UserID = userID

	var entries []*domain.JournalEntry
	var err error

	// Apply filters
	switch {
	case filter.Search != "":
		entries, err = uc.journalRepo.SearchByContent(ctx, userID, filter.Search, filter.Limit, filter.Offset)
	case len(filter.Tags) > 0:
		entries, err = uc.journalRepo.GetByUserIDAndTags(ctx, userID, filter.Tags, filter.Limit, filter.Offset)
	case filter.Type != "":
		entries, err = uc.journalRepo.GetByUserIDAndType(ctx, userID, filter.Type, filter.Limit, filter.Offset)
	case filter.StartDate != nil && filter.EndDate != nil:
		entries, err = uc.journalRepo.GetByUserIDAndDateRange(ctx, userID, *filter.StartDate, *filter.EndDate)
	default:
		entries, err = uc.journalRepo.GetByUserID(ctx, userID, filter.Limit, filter.Offset)
	}

	if err != nil {
		return nil, fmt.Errorf("failed to get journal entries: %w", err)
	}

	// Get total count
	total, err := uc.journalRepo.Count(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get total count: %w", err)
	}

	// Map to DTOs
	entryDTOs := make([]dto.JournalEntryResponse, len(entries))
	for i, entry := range entries {

		var res dto.JournalEntryResponse
		if err := utils.TypeConverter(entry, &res); err != nil {

			return nil, fmt.Errorf("failed to create journal entry: %w", err)
		}
		entryDTOs[i] = res
	}

	totalPages := int(math.Ceil(float64(total) / float64(filter.Limit)))
	hasMore := filter.Offset+filter.Limit < int(total)

	return &dto.JournalEntriesResponse{
		Entries:    entryDTOs,
		Total:      total,
		Limit:      filter.Limit,
		Offset:     filter.Offset,
		HasMore:    hasMore,
		TotalPages: totalPages,
	}, nil
}

// UpdateEntry updates an existing journal entry
func (uc *journalUseCase) UpdateEntry(ctx context.Context, userID, entryID string, req dto.UpdateJournalEntryRequest) (*dto.JournalEntryResponse, error) {
	var res dto.JournalEntryResponse
	entry, err := uc.journalRepo.GetByID(ctx, entryID)
	if err != nil {
		return nil, domain.ErrEntryNotFound
	}

	if entry.UserID != userID {
		return nil, domain.ErrUnauthorized
	}

	// Update fields if provided

	if req.Content != nil {
		content := strings.TrimSpace(*req.Content)
		if content == "" {
			return nil, domain.ErrEmptyContent
		}
		entry.Content = content
	}
	if req.Tags != nil {
		entry.Tags = sanitizeTags(req.Tags)
	}
	entry.UpdatedAt = time.Now()

	if err := uc.journalRepo.Update(ctx, entry); err != nil {
		return nil, fmt.Errorf("failed to update journal entry: %w", err)
	}

	if err := utils.TypeConverter(entry, &res); err != nil {

		return nil, fmt.Errorf("failed to create journal entry: %w", err)
	}
	return &res, nil
}

// DeleteEntry deletes a journal entry
func (uc *journalUseCase) DeleteEntry(ctx context.Context, userID, entryID string) error {
	entry, err := uc.journalRepo.GetByID(ctx, entryID)
	if err != nil {
		return domain.ErrEntryNotFound
	}

	if entry.UserID != userID {
		return domain.ErrUnauthorized
	}

	if err := uc.journalRepo.Delete(ctx, entryID); err != nil {
		return fmt.Errorf("failed to delete journal entry: %w", err)
	}

	return nil
}

// GetTodayEntry retrieves today's entry for a specific type
func (uc *journalUseCase) GetTodayEntry(ctx context.Context, userID, entryType string) (*dto.TodayEntryResponse, error) {
	var res dto.JournalEntryResponse
	if !utils.IsValidEntryType(entryType) {
		return nil, domain.ErrInvalidEntryType
	}

	entry, err := uc.journalRepo.GetTodayEntry(ctx, userID, entryType)
	if err != nil {
		return &dto.TodayEntryResponse{
			Entry:  nil,
			Exists: false,
		}, nil
	}
	if err := utils.TypeConverter(entry, &res); err != nil {

		return nil, fmt.Errorf("failed to get journal entry: %w", err)
	}
	return &dto.TodayEntryResponse{
		Entry:  &res,
		Exists: true,
	}, nil
}

// GetStats retrieves journal statistics for a user
func (uc *journalUseCase) GetStats(ctx context.Context, userID string) (*dto.JournalStatsResponse, error) {
	var res dto.JournalEntryResponse
	// Get total entries
	totalEntries, err := uc.journalRepo.Count(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get total entries: %w", err)
	}

	// Get entries by type
	entriesByType := make(map[string]int64)
	for _, entryType := range utils.GetJournalEntryTypes() {
		count, err := uc.journalRepo.CountByType(ctx, userID, entryType)
		if err != nil {
			return nil, fmt.Errorf("failed to get count for type %s: %w", entryType, err)
		}
		entriesByType[entryType] = count
	}

	// Get recent activity (last 5 entries)
	recentEntries, err := uc.journalRepo.GetByUserID(ctx, userID, 5, 0)
	if err != nil {
		return nil, fmt.Errorf("failed to get recent entries: %w", err)
	}

	recentActivity := make([]dto.JournalEntryResponse, len(recentEntries))
	for i, entry := range recentEntries {
		if err := utils.TypeConverter(entry, &res); err != nil {

			return nil, fmt.Errorf("failed to get journal entry: %w", err)
		}
		recentActivity[i] = res
	}

	// Calculate streaks
	currentStreak, longestStreak := uc.calculateStreaks(ctx, userID)

	// Get tags usage
	tagsUsage := uc.calculateTagsUsage(recentEntries)

	// Get monthly progress (last 6 months)
	monthlyProgress := uc.calculateMonthlyProgress(ctx, userID)

	return &dto.JournalStatsResponse{
		TotalEntries:    totalEntries,
		EntriesByType:   entriesByType,
		CurrentStreak:   currentStreak,
		LongestStreak:   longestStreak,
		TagsUsage:       tagsUsage,
		RecentActivity:  recentActivity,
		MonthlyProgress: monthlyProgress,
	}, nil
}

// SearchEntries searches journal entries by content
func (uc *journalUseCase) SearchEntries(ctx context.Context, userID, query string, limit, offset int) (*dto.JournalEntriesResponse, error) {
	var res dto.JournalEntryResponse
	if strings.TrimSpace(query) == "" {
		return &dto.JournalEntriesResponse{
			Entries: []dto.JournalEntryResponse{},
			Total:   0,
		}, nil
	}

	entries, err := uc.journalRepo.SearchByContent(ctx, userID, query, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to search entries: %w", err)
	}

	entryDTOs := make([]dto.JournalEntryResponse, len(entries))
	for i, entry := range entries {
		if err := utils.TypeConverter(entry, &res); err != nil {

			return nil, fmt.Errorf("failed to get journal entry: %w", err)
		}
		entryDTOs[i] = res
	}

	return &dto.JournalEntriesResponse{
		Entries: entryDTOs,
		Total:   int64(len(entryDTOs)),
		Limit:   limit,
		Offset:  offset,
	}, nil
}

func sanitizeTags(tags []string) []string {
	var sanitized []string
	seen := make(map[string]bool)

	for _, tag := range tags {
		tag = strings.TrimSpace(tag)
		if tag != "" && !seen[tag] && len(tag) <= 50 {
			sanitized = append(sanitized, tag)
			seen[tag] = true
		}
	}

	return sanitized
}

func (uc *journalUseCase) calculateTagsUsage(entries []*domain.JournalEntry) map[string]int {
	tagsUsage := make(map[string]int)

	for _, entry := range entries {
		for _, tag := range entry.Tags {
			tagsUsage[tag]++
		}
	}

	return tagsUsage
}

func (uc *journalUseCase) calculateStreaks(ctx context.Context, userID string) (int, int) {
	// Get entries for the last 60 days to accurately calculate streaks
	sixtyDaysAgo := time.Now().AddDate(0, 0, -60).Format("2006-01-02")

	entries, err := uc.journalRepo.GetEntriesByUserIDAndDateRange(ctx, userID, sixtyDaysAgo)
	if err != nil {
		// In a real application, you'd log this error
		// For simplicity, returning 0,0 on error, but better error handling is needed.
		return 0, 0
	}

	if len(entries) == 0 {
		return 0, 0
	}

	currentStreak := 0
	longestStreak := 0
	consecutiveDays := 0

	// Use a map to store unique dates with entries to handle multiple entries on the same day
	entryDates := make(map[string]bool)
	for _, entry := range entries {
		entryDates[entry.CreatedAt.Format("2006-01-02")] = true
	}

	// Collect unique dates into a slice for sorting
	var sortedDates []time.Time
	for dateStr := range entryDates {
		parsedDate, err := time.Parse("2006-01-02", dateStr)
		if err == nil {
			sortedDates = append(sortedDates, parsedDate)
		}
	}

	// Sort dates in ascending order
	// This step is crucial if entries are not naturally ordered or if fetching method doesn't guarantee it.
	sort.Slice(sortedDates, func(i, j int) bool {
		return sortedDates[i].Before(sortedDates[j])
	})

	// Calculate longest streak
	if len(sortedDates) > 0 {
		consecutiveDays = 1
		longestStreak = 1
		for i := 1; i < len(sortedDates); i++ {
			// Check if the current date is exactly one day after the previous date
			if sortedDates[i].Sub(sortedDates[i-1]) == 24*time.Hour {
				consecutiveDays++
			} else {
				consecutiveDays = 1 // Reset if not consecutive
			}
			if consecutiveDays > longestStreak {
				longestStreak = consecutiveDays
			}
		}
	}

	// Calculate current streak
	currentStreak = 0
	if len(sortedDates) > 0 {
		nowTruncated := time.Now().Truncate(24 * time.Hour)  // Today's date without time
		yesterdayTruncated := nowTruncated.AddDate(0, 0, -1) // Yesterday's date without time

		latestEntryDate := sortedDates[len(sortedDates)-1] // Get the most recent entry date from the sorted list

		// If the latest entry is today
		if latestEntryDate.Equal(nowTruncated) {
			currentStreak = 1
			// Go backwards from today to find consecutive days
			for i := len(sortedDates) - 2; i >= 0; i-- {
				// Check if the difference between the current date and the one before it is exactly 24 hours
				if latestEntryDate.Sub(sortedDates[i]) == 24*time.Hour {
					currentStreak++
					latestEntryDate = sortedDates[i] // Move to the previous date for the next comparison
				} else {
					break // Not consecutive
				}
			}
		} else if latestEntryDate.Equal(yesterdayTruncated) {
			// If the latest entry was yesterday, the streak ends yesterday.
			// We count backwards from yesterday.
			currentStreak = 1
			for i := len(sortedDates) - 2; i >= 0; i-- {
				if latestEntryDate.Sub(sortedDates[i]) == 24*time.Hour {
					currentStreak++
					latestEntryDate = sortedDates[i]
				} else {
					break
				}
			}
		}
		// If the latest entry is older than yesterday, current streak remains 0.
	}

	return currentStreak, longestStreak
}

// calculateMonthlyProgress calculates journal entry progress for the last 6 months.
func (uc *journalUseCase) calculateMonthlyProgress(ctx context.Context, userID string) []dto.MonthlyProgressEntry {
	var progress []dto.MonthlyProgressEntry
	now := time.Now()

	for i := 5; i >= 0; i-- {
		month := now.AddDate(0, -i, 0)
		firstDayOfMonth := time.Date(month.Year(), month.Month(), 1, 0, 0, 0, 0, now.Location())
		lastDayOfMonth := firstDayOfMonth.AddDate(0, 1, -1) // Last day of the current month

		monthStr := month.Format("2006-01")

		count, err := uc.journalRepo.CountEntriesByUserIDAndDateRange(ctx, userID, firstDayOfMonth, lastDayOfMonth)
		if err != nil {
			logger.Log.WithError(err).Error("Could not get count")
			count = 0
		}

		// Calculate target based on days in month (excluding future days for current month)
		target := 30 // Default target for a month (can be adjusted)
		if month.Year() == now.Year() && month.Month() == now.Month() {
			// For the current month, target is number of days passed so far
			target = now.Day()
		} else {
			target = lastDayOfMonth.Day() // Number of days in the month
		}

		percent := float64(0)
		if target > 0 {
			percent = (float64(count) / float64(target)) * 100
		}

		progress = append(progress, dto.MonthlyProgressEntry{
			Month:   monthStr,
			Count:   count,
			Target:  target,
			Percent: int(percent),
		})
	}
	return progress
}
