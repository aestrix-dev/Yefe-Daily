package repository

import (
	"context"
	"strings"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/infrastructure/db/models"
	"yefe_app/v1/pkg/logger"
	"yefe_app/v1/pkg/utils"

	"gorm.io/gorm"
)

type journalRepository struct {
	db *gorm.DB
}

// NewJournalRepository creates a new journal repository
func NewJournalRepository(db *gorm.DB) domain.JournalRepository {
	return &journalRepository{db: db}
}

func (r *journalRepository) Create(ctx context.Context, entry *domain.JournalEntry) error {
	var dbEntry models.JournalEntry
	err := utils.TypeConverter(entry, &dbEntry)
	if err != nil {
		logger.Log.WithError(err).Error("entry domain to model error")
		return err
	}
	return r.db.WithContext(ctx).Create(&dbEntry).Error
}

func (r *journalRepository) GetByID(ctx context.Context, id string) (*domain.JournalEntry, error) {
	var dbentry models.JournalEntry
	var entry domain.JournalEntry
	err := r.db.WithContext(ctx).Where("id = ?", id).First(&dbentry).Error
	if err != nil {
		return nil, err
	}
	err = utils.TypeConverter(dbentry, &entry)
	if err != nil {
		return nil, err
	}
	return &entry, nil
}

func (r *journalRepository) GetByUserID(ctx context.Context, userID string, limit, offset int) ([]*domain.JournalEntry, error) {
	var dbentries []*models.JournalEntry
	var entries []*domain.JournalEntry

	query := r.db.WithContext(ctx).Where("user_id = ?", userID).Order("created_at DESC")

	if limit > 0 {
		query = query.Limit(limit)
	}
	if offset > 0 {
		query = query.Offset(offset)
	}

	err := query.Find(&dbentries).Error
	err = utils.TypeConverter(dbentries, &entries)
	if err != nil {
		return nil, err
	}
	return entries, err
}

func (r *journalRepository) GetByUserIDAndType(ctx context.Context, userID, entryType string, limit, offset int) ([]*domain.JournalEntry, error) {
	var entries []*domain.JournalEntry
	query := r.db.WithContext(ctx).Where("user_id = ? AND type = ?", userID, entryType).Order("created_at DESC")

	if limit > 0 {
		query = query.Limit(limit)
	}
	if offset > 0 {
		query = query.Offset(offset)
	}

	err := query.Find(&entries).Error
	return entries, err
}

func (r *journalRepository) GetByUserIDAndDateRange(ctx context.Context, userID string, startDate, endDate time.Time) ([]*domain.JournalEntry, error) {
	var entries []*domain.JournalEntry
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND created_at BETWEEN ? AND ?", userID, startDate, endDate).
		Order("created_at DESC").
		Find(&entries).Error
	return entries, err
}

func (r *journalRepository) GetByUserIDAndTags(ctx context.Context, userID string, tags []string, limit, offset int) ([]*domain.JournalEntry, error) {
	var entries []*domain.JournalEntry
	query := r.db.WithContext(ctx).Where("user_id = ?", userID)

	// For JSON array search in different databases
	for _, tag := range tags {
		query = query.Where("JSON_CONTAINS(tags, ?)", `"`+tag+`"`)
	}

	query = query.Order("created_at DESC")

	if limit > 0 {
		query = query.Limit(limit)
	}
	if offset > 0 {
		query = query.Offset(offset)
	}

	err := query.Find(&entries).Error
	return entries, err
}

func (r *journalRepository) Update(ctx context.Context, entry *domain.JournalEntry) error {
  var dbJournal models.JournalEntry
  err := utils.TypeConverter(entry, &dbJournal)
  if err != nil{
    return err
  }
	return r.db.WithContext(ctx).Save(dbJournal).Error
}

func (r *journalRepository) Delete(ctx context.Context, id string) error {
	return r.db.WithContext(ctx).Delete(&models.JournalEntry{}, "id = ?", id).Error
}

func (r *journalRepository) Count(ctx context.Context, userID string) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&models.JournalEntry{}).Where("user_id = ?", userID).Count(&count).Error
	return count, err
}

func (r *journalRepository) CountByType(ctx context.Context, userID, entryType string) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&models.JournalEntry{}).
		Where("user_id = ? AND type = ?", userID, entryType).Count(&count).Error
	return count, err
}

func (r *journalRepository) SearchByContent(ctx context.Context, userID, query string, limit, offset int) ([]*domain.JournalEntry, error) {
	var entries []*domain.JournalEntry
	searchQuery := "%" + strings.ToLower(query) + "%"

	dbQuery := r.db.WithContext(ctx).
		Where("user_id = ? AND (LOWER(content) LIKE ?)",
			userID, searchQuery, searchQuery).
		Order("created_at DESC")

	if limit > 0 {
		dbQuery = dbQuery.Limit(limit)
	}
	if offset > 0 {
		dbQuery = dbQuery.Offset(offset)
	}

	err := dbQuery.Find(&entries).Error
	return entries, err
}

func (r *journalRepository) GetTodayEntry(ctx context.Context, userID, entryType string) (*domain.JournalEntry, error) {
	var dbentry models.JournalEntry
	var entry domain.JournalEntry
	today := time.Now().Truncate(24 * time.Hour)
	tomorrow := today.Add(24 * time.Hour)

	err := r.db.WithContext(ctx).
		Where("user_id = ? AND type = ? AND created_at >= ? AND created_at < ?",
			userID, entryType, today, tomorrow).
		First(&dbentry).Error

	if err != nil {
		return nil, err
	}
	if err = utils.TypeConverter(dbentry, &entry); err != nil {
		return nil, err
	}

	return &entry, nil
}

// GetEntriesByUserIDAndDateRange retrieves journal entries for a user within a specified date range.
func (r *journalRepository) GetEntriesByUserIDAndDateRange(ctx context.Context, userID string, startDate string) ([]domain.JournalEntry, error) {
	var dbentries []models.JournalEntry
	var entries []domain.JournalEntry
	result := r.db.WithContext(ctx).Where("user_id = ? AND created_at >= ?", userID, startDate).
		Order("created_at asc").Find(&dbentries)
	if result.Error != nil {
		return nil, result.Error
	}
	if err := utils.TypeConverter(dbentries, &entries); err != nil {
		return nil, err
	}
	return entries, nil
}

// CountEntriesByUserIDAndDateRange counts journal entries for a user within a specified date range.
func (r *journalRepository) CountEntriesByUserIDAndDateRange(ctx context.Context, userID string, startDate, endDate time.Time) (int64, error) {
	var count int64
	result := r.db.WithContext(ctx).Model(&models.JournalEntry{}).
		Where("user_id = ? AND created_at >= ? AND created_at <= ?", userID, startDate, endDate).
		Count(&count)
	if result.Error != nil {
		return 0, result.Error
	}
	return count, nil
}
