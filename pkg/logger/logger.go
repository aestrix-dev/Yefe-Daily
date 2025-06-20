package logger

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"
	"yefe_app/v1/pkg/utils"

	"github.com/sirupsen/logrus"
)

var Log *logrus.Logger

type dailyLogWriter struct {
	dir     string
	prefix  string
	current string
	file    *os.File
}

func newDailyLogWriter(dir, prefix string) *dailyLogWriter {
	return &dailyLogWriter{
		dir:    dir,
		prefix: prefix,
	}
}

func (w *dailyLogWriter) Write(p []byte) (int, error) {
	today := time.Now().Format("2006-01-02")
	filename := filepath.Join(w.dir, fmt.Sprintf("%s-%s.log", w.prefix, today))

	if filename != w.current {
		if w.file != nil {
			w.file.Close()
		}
		err := os.MkdirAll(w.dir, 0755)
		if err != nil {
			return 0, err
		}
		file, err := os.OpenFile(filename, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0644)
		if err != nil {
			return 0, err
		}
		w.file = file
		w.current = filename
	}

	return w.file.Write(p)
}

func Init() {
	err := utils.LoadEnv()
	if err != nil {
		panic(err)
	}

	Log = logrus.New()

	// === Setup Daily File Writer ===
	logDir := os.Getenv("LOG_DIR")
	if logDir == "" {
		logDir = "logs"
	}

	logPrefix := os.Getenv("LOG_FILE_PREFIX")
	if logPrefix == "" {
		logPrefix = "server"
	}

	dailyWriter := newDailyLogWriter(logDir, logPrefix)

	// === Combine stdout + file ===
	Log.SetOutput(io.MultiWriter(os.Stdout, dailyWriter))

	// === Formatter ===
	if strings.ToLower(os.Getenv("LOG_FORMAT")) == "json" {
		Log.SetFormatter(&logrus.JSONFormatter{
			TimestampFormat: "2006-01-02T15:04:05Z07:00",
		})
	} else {
		Log.SetFormatter(&logrus.TextFormatter{
			FullTimestamp: true,
		})
	}

	// === Level ===
	level := os.Getenv("LOG_LEVEL")
	parsedLevel, err := logrus.ParseLevel(level)
	if err != nil {
		parsedLevel = logrus.InfoLevel
	}
	Log.SetLevel(parsedLevel)
}
