package dto

import "time"

// RecordSleepRequest represents the request body for recording a sleep entry.
type RecordSleepRequest struct {
	SleptAt  time.Time `json:"slept_at" validate:"required"`
	WokeUpAt time.Time `json:"woke_up_at" validate:"required"`
}
