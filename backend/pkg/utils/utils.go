package utils

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/base32"
	"encoding/json"
	"os"
	"path"
	"sync"
	"yefe_app/v1/pkg/types"

	envsubt "github.com/emperorsixpacks/envsubst"
	"github.com/google/uuid"
	"github.com/joho/godotenv"
	"golang.org/x/crypto/argon2"
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
		Name   string `yaml:"name"`
		Port   int    `yaml:"port"`
		Host   string `yaml:"host"`
		Secret string `yaml:"secret"`
	}
	PersistenceSettings struct {
		PostgresSQl DBSettings `yaml:"postgres"`
		Redis       DBSettings `yaml:"redis"`
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

func GenerateSalt(length uint32) string {
	salt := make([]byte, length)
	rand.Read(salt)
	return base32.StdEncoding.EncodeToString(salt)
}

func HashPassword(password, salt string, config types.PasswordConfig) string {
	saltBytes, _ := base32.StdEncoding.DecodeString(salt)
	hash := argon2.IDKey([]byte(password), saltBytes, config.Iterations, config.Memory, config.Parallelism, config.KeyLength)
	return base32.StdEncoding.EncodeToString(hash)
}

func VerifyPassword(password, salt, hash string, config types.PasswordConfig) bool {
	saltBytes, _ := base32.StdEncoding.DecodeString(salt)
	hashBytes, _ := base32.StdEncoding.DecodeString(hash)
	expectedHash := argon2.IDKey([]byte(password), saltBytes, config.Iterations, config.Memory, config.Parallelism, config.KeyLength)
	return subtle.ConstantTimeCompare(hashBytes, expectedHash) == 1
}

func GenerateSecureToken() string {
	bytes := make([]byte, 32)
	rand.Read(bytes)
	return base32.StdEncoding.EncodeToString(bytes)
}

// generateID generates a new UUID
func GenerateID() string {
	return uuid.NewString()
}

func TypeConverter(in any, out any) error {
	input, err := json.Marshal(in)
	if err != nil {
		return err
	}
	err = json.Unmarshal(input, out)
	return nil
}
