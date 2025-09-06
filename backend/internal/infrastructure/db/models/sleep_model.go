package models

import (
	"time"
	"yefe_app/v1/pkg/utils"

	"gorm.io/gorm"
)

// Sleep represents a sleep record for a user.
type Sleep struct {
	ID        string    `json:"id" gorm:"primary_key"`
	UserID    string    `json:"user_id"`
	SleptAt   time.Time `json:"slept_at"`
	WokeUpAt  time.Time `json:"woke_up_at"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

func (ct *Sleep) BeforeCreate(tx *gorm.DB) error {
	ct.ID = utils.GenerateID()
	return nil
}
