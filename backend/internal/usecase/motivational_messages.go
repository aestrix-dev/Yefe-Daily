package usecase

import (
	"encoding/json"
	"math/rand"
	"os"
	"time"

	"yefe_app/v1/pkg/logger"
)

var messages []string

func LoadMessages(filePath string) error {
	file, err := os.ReadFile(filePath)
	if err != nil {
		return err
	}

	// Check if the file is empty
	if len(file) == 0 {
		logger.Log.Warn("motivational_messages.json is empty")
		return nil
	}

	// Check if the content is a valid JSON array
	if err := json.Unmarshal(file, &messages); err != nil {
		logger.Log.WithError(err).Error("Failed to parse motivational_messages.json")
		return err
	}

	logger.Log.Info("Successfully loaded messages from motivational_messages.json")
	return nil
}

func GetRandomMessage() string {
	if len(messages) == 0 {
		return "Here's your daily dose of motivation!"
	}
	rand.Seed(time.Now().UnixNano())
	return messages[rand.Intn(len(messages))]
}
