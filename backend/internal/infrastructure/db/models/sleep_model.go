package models

import "time"

// Sleep represents a sleep record for a user.
type Sleep struct {
	ID        uint      `json:"id" gorm:"primary_key"`
	UserID    uint      `json:"user_id"`
	SleptAt   time.Time `json:"slept_at"`
	WokeUpAt  time.Time `json:"woke_up_at"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
