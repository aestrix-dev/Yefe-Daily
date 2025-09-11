package utils

import (
	"encoding/json"
	"fmt"
	"os"
	"time"
)

var messages []string

func LoadMessages(filePath string) error {
	file, err := os.ReadFile(filePath)
	if err != nil {
		return err
	}

	// Check if the file is empty
	if len(file) == 0 {
		return fmt.Errorf("motivational_messages.json is empty")
	}

	// Check if the content is a valid JSON array
	if err := json.Unmarshal(file, &messages); err != nil {
		return fmt.Errorf("Failed to parse motivational_messages.json")
	}
	return nil
}

func GetRandomMessage() string {
	if len(messages) == 0 {
		return "Here's your daily dose of motivation!"
	}
	index := int(time.Now().UnixNano()) % len(messages)

	return messages[index]
}
