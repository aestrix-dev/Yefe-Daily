package utils

import (
	"os"
	"path"
	"sync"

	envsubt "github.com/emperorsixpacks/envsubst"
	"github.com/joho/godotenv"
)

var (
	once        sync.Once
	basePath, _ = getBasePath()
	LogDir      = path.Join(basePath, "logs")
)

type (
	AppSettings struct {
		Server      ServerSettings      `yaml:"server"`
		Persistence PersistenceSettings `yaml:"persistence"`
	}
	ServerSettings struct {
		Name string `yaml:"name"`
		Port int    `yaml:"port"`
		Host string `yaml:"host"`
	}
	PersistenceSettings struct {
		PostgresSQl DBSettings `yaml:"postgres"`
	}
	DBSettings struct {
		Host          string `yaml:"host"`
		Port          string `yaml:"port"`
		ConnectionUrl string `yaml:"connection_url"`
		UserName      string `yaml:"username"`
		Password      string `yaml:"password"`
		DataBase      string `yaml:"database"`
	}
)

func LoadEnv() error {
	pathStr, err := getBasePath()
	if err != nil {
		return err
	}
	envPath := path.Join(pathStr, "config", ".env")

	err = validPath(envPath)
	if err != nil {
		return err
	}
	err = godotenv.Load(envPath)
	if err != nil {
		return err
	}
	return nil
}
func LoadConfig() (AppSettings, error) {
	err := LoadEnv()
	if err != nil {
		return AppSettings{}, err
	}
	pathStr, err := getBasePath()
	if err != nil {
		return AppSettings{}, err
	}
	ymlPath := path.Join(pathStr, "config/config.yaml")
	err = validPath(ymlPath)

	if err != nil {
		return AppSettings{}, err

	}
	var app_settings AppSettings
	yamlBytes, err := os.ReadFile(ymlPath)
	once.Do(func() {
		err := envsubt.Unmarshal(yamlBytes, &app_settings)
		if err != nil {
			panic(err)
		}
	})
	return app_settings, nil
}
