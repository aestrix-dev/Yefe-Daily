package utils

import (
	"os"
	"path"
	"sync"

	"github.com/joho/godotenv"
	"gopkg.in/yaml.v3"
)

var (
	once         sync.Once
	app_settings *AppSettings
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
func LoadConfig() AppSettings {
	pathStr, err := getBasePath()
	if err != nil {
		panic(err)
	}
	ymlPath := path.Join(pathStr, "config/config.yml")
	err = validPath(ymlPath)

	if err != nil {
		panic(err)

	}
	yamlBytes, err := os.ReadFile(ymlPath)
	once.Do(func() {
		err := yaml.Unmarshal(yamlBytes, &app_settings)
		if err != nil {
			panic(err)
		}
	})
	return *app_settings
}
