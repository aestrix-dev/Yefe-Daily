package utils

import (
	"errors"
	"os"
	"path"
	"runtime"
)

// Returns the root dir
func getBasePath() (string, error) {
	_, basePath, _, ok := runtime.Caller(0)
	if !ok {
		return "", errors.New("Could not get file path")
	}
	return path.Dir(path.Dir(path.Dir(path.Dir(basePath)))), nil
}

func validPath(configPath string) error {
	_, err := os.Stat(configPath)
	if !os.IsNotExist(err) {
		return err
	}
	return nil
}
