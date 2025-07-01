package models

import (
	"time"
	"yefe_app/v1/pkg/types"

	"gorm.io/gorm"
)

// JournalEntry represents the database model for journal entries
type JournalEntry struct {
	ID        string         `gorm:"primaryKey;type:varchar(36)" json:"id"`
	UserID    string         `gorm:"not null;type:varchar(36);index:idx_user_entries" json:"user_id"`
	Content   string         `gorm:"type:text;not null" json:"content"`
	Type      string         `gorm:"type:varchar(20);not null;index:idx_user_type" json:"type"`
	Tags      types.Tags     `gorm:"type:varchar(20)" json:"tags"`
	CreatedAt time.Time      `gorm:"not null;index:idx_created_at" json:"created_at"`
	User      User           `gorm:"foreignKey:UserID" json:"-"`
	UpdatedAt time.Time      `gorm:"not null" json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

// TableName returns the table name for the JournalEntry model
func (JournalEntry) TableName() string {
	return "journal_entries"
}

// BeforeCreate is a GORM hook that runs before creating a record
func (j *JournalEntry) BeforeCreate(tx *gorm.DB) error {
	if j.CreatedAt.IsZero() {
		j.CreatedAt = time.Now()
	}
	if j.UpdatedAt.IsZero() {
		j.UpdatedAt = time.Now()
	}
	return nil
}

// BeforeUpdate is a GORM hook that runs before updating a record
func (j *JournalEntry) BeforeUpdate(tx *gorm.DB) error {
	j.UpdatedAt = time.Now()
	return nil
}

// JournalEntryTag represents the many-to-many relationship between entries and tags
// This is an alternative approach if you want normalized tag storage
type JournalEntryTag struct {
	ID        string    `gorm:"primaryKey;type:varchar(36)" json:"id"`
	EntryID   string    `gorm:"not null;type:varchar(36);index:idx_entry_tags" json:"entry_id"`
	TagName   string    `gorm:"not null;type:varchar(50);index:idx_tag_name" json:"tag_name"`
	CreatedAt time.Time `gorm:"not null" json:"created_at"`

	// Foreign key relationships
	Entry JournalEntry `gorm:"foreignKey:EntryID;constraint:OnDelete:CASCADE" json:"-"`
}

// TableName returns the table name for the JournalEntryTag model
func (JournalEntryTag) TableName() string {
	return "journal_entry_tags"
}

// JournalStreak represents user's journaling streaks
type JournalStreak struct {
	ID            string    `gorm:"primaryKey;type:varchar(36)" json:"id"`
	UserID        string    `gorm:"not null;type:varchar(36);uniqueIndex:idx_user_streak" json:"user_id"`
	CurrentStreak int       `gorm:"default:0" json:"current_streak"`
	LongestStreak int       `gorm:"default:0" json:"longest_streak"`
	LastEntryDate time.Time `gorm:"type:date" json:"last_entry_date"`
	CreatedAt     time.Time `gorm:"not null" json:"created_at"`
	UpdatedAt     time.Time `gorm:"not null" json:"updated_at"`
}

// TableName returns the table name for the JournalStreak model
func (JournalStreak) TableName() string {
	return "journal_streaks"
}

// JournalTemplate represents predefined templates for journal entries
type JournalTemplate struct {
	ID        string    `gorm:"primaryKey;type:varchar(36)" json:"id"`
	Name      string    `gorm:"not null;type:varchar(100);index:idx_template_name" json:"name"`
	Type      string    `gorm:"type:varchar(20);not null;index:idx_template_type" json:"type"`
	Content   string    `gorm:"type:text" json:"content"`
	Prompts   []string  `gorm:"type:json" json:"prompts"`
	Tags      []string  `gorm:"type:json" json:"tags"`
	IsActive  bool      `gorm:"default:true" json:"is_active"`
	IsDefault bool      `gorm:"default:false" json:"is_default"`
	CreatedBy string    `gorm:"type:varchar(36)" json:"created_by"` // Admin user ID
	CreatedAt time.Time `gorm:"not null" json:"created_at"`
	UpdatedAt time.Time `gorm:"not null" json:"updated_at"`
}

// JournalReminder represents reminders for journal entries
type JournalReminder struct {
	ID        string    `gorm:"primaryKey;type:varchar(36)" json:"id"`
	UserID    string    `gorm:"not null;type:varchar(36);index:idx_user_reminders" json:"user_id"`
	Type      string    `gorm:"type:varchar(20);not null" json:"type"` // morning, evening, wisdom_note
	Time      string    `gorm:"type:varchar(5);not null" json:"time"`  // HH:MM format
	Days      []string  `gorm:"type:json" json:"days"`                 // ["monday", "tuesday", ...]
	IsActive  bool      `gorm:"default:true" json:"is_active"`
	Message   string    `gorm:"type:varchar(255)" json:"message"`
	CreatedAt time.Time `gorm:"not null" json:"created_at"`
	UpdatedAt time.Time `gorm:"not null" json:"updated_at"`
}

// TableName returns the table name for the JournalTemplate model
func (JournalTemplate) TableName() string {
	return "journal_templates"
}

// TableName returns the table name for the JournalReminder model
func (JournalReminder) TableName() string {
	return "journal_reminders"
}
