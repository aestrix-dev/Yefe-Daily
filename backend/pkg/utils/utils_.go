package utils

import (
	"errors"
	"fmt"
	"os"
	"path"
	"runtime"

	"github.com/go-playground/validator"
)

// Returns the root dir
func getBasePath() (string, error) {
	_, basePath, _, ok := runtime.Caller(0)
	if !ok {
		return "", errors.New("Could not get file path")
	}
	return path.Dir(path.Dir(path.Dir(basePath))), nil
}

func validPath(configPath string) error {
	_, err := os.Stat(configPath)
	if !os.IsNotExist(err) {
		return err
	}
	return nil
}

func formatValidationErrors(err error) interface{} {
	var errors []map[string]string
	if validationErrors, ok := err.(validator.ValidationErrors); ok {
		for _, e := range validationErrors {
			errors = append(errors, map[string]string{
				"field":   e.Field(),
				"message": getValidationMessage(e),
			})
		}
	}
	return errors
}

func getValidationMessage(e validator.FieldError) string {
	switch e.Tag() {
	case "required":
		return "This field is required"
	case "email":
		return "Invalid email format"
	case "min":
		return fmt.Sprintf("Minimum length is %s", e.Param())
	case "max":
		return fmt.Sprintf("Maximum length is %s", e.Param())
	case "len":
		return fmt.Sprintf("Length must be %s", e.Param())
	case "eqfield":
		return "Passwords do not match"
	default:
		return "Invalid value"
	}
}
