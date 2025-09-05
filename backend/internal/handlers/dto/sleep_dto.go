package dto

import "time"

// RecordSleepRequest represents the request body for recording a sleep entry.
type RecordSleepRequest struct {
	SleptAt  time.Time `json:"slept_at" validate:"required"`
	WokeUpAt time.Time `json:"woke_up_at" validate:"required"`
}

// SleepGraphData represents the sleep data for the graph.
type SleepGraphData struct {
	Date     time.Time `json:"date"`
	Duration float64   `json:"duration"`
	DayOfWeek string   `json:"day_of_week"`
}

// SleepGraphResponse represents the response for sleep graph data.
type SleepGraphResponse struct {
	GraphData []SleepGraphData `json:"graph_data"`
	AverageSleepDuration float64 `json:"average_sleep_duration"`
	TotalEntries int `json:"total_entries"`
}
