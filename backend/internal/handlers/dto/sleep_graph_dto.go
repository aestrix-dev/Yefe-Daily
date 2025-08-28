package dto

import "time"

// SleepGraphData represents the data for a single day in the sleep graph.

type SleepGraphData struct {
	Date     time.Time `json:"date"`
	Duration float64   `json:"duration"`
}
