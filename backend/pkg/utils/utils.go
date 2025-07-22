package utils

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/base32"
	"encoding/json"
	"fmt"
	"os"
	"path"
	"slices"
	"sync"
	"time"
	"yefe_app/v1/pkg/types"

	envsubt "github.com/emperorsixpacks/envsubst"
	"github.com/google/uuid"
	"github.com/joho/godotenv"
	"golang.org/x/crypto/argon2"
)

var (
	once        sync.Once
	basePath, _ = GetBasePath()
	LogDir      = path.Join(basePath, "logs")
)

var DefaultPasswordConfig = types.PasswordConfig{
	Memory:      64 * 1024, // MB
	Iterations:  3,
	Parallelism: 2,
	SaltLength:  16,
	KeyLength:   32,
}

type (
	AppSettings struct {
		Server         ServerSettings      `yaml:"server"`
		Persistence    PersistenceSettings `yaml:"persistence"`
		EmailConfig    EmailConfig         `yaml:"email_config"`
		StripeConfig   PaymentConfig       `yaml:"payment_config"`
		FirebaseConfig FirebaseConfig      `yaml:"firebase_config"`
	}
	FirebaseConfig struct {
		Type                    string `yaml:"type"`
		ProjectID               string `yaml:"project_id"`
		PrivateKeyID            string `yaml:"private_key_id"`
		PrivateKey              string `yaml:"private_key"`
		ClientEmail             string `yaml:"client_email"`
		ClientID                string `yaml:"client_id"`
		AuthURI                 string `yaml:"auth_uri"`
		TokenURI                string `yaml:"token_uri"`
		AuthProviderX509CertURL string `yaml:"auth_provider_x509_cert_url"`
		ClientX509CertURL       string `yaml:"client_x509_cert_url"`
		UniverseDomain          string `yaml:"universe_domain"`
	}

	ServerSettings struct {
		Name         string `yaml:"name"`
		Port         int    `yaml:"port"`
		Host         string `yaml:"host"`
		Secret       string `yaml:"secret"`
		DevURl       string `yaml:"dev_url"`
		ProdURL      string `yaml:"prod_url,omitempty"`
		Env          string `yaml:"environment"`
		AllowedHosts string `yaml:"allowed_hosts"`
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
	EmailConfig struct {
		SMTPHost      string        `yaml:"smtp_host"`
		SMTPPort      string        `yaml:"smtp_port"`
		SMTPUsername  string        `yaml:"smtp_username"`
		SMTPPassword  string        `yaml:"smtp_password"`
		FromEmail     string        `yaml:"from_email"`
		FromName      string        `yaml:"from_name"`
		UseTLS        bool          `yaml:"use_tls"`
		WorkerCount   int           `yaml:"worker_count"`
		QueueSize     int           `yaml:"queue_size"`
		RetryAttempts int           `yaml:"retry_attempts"`
		RetryDelay    time.Duration `yaml:"retry_delay"`
	}
	PaymentConfig struct {
		SecretKey          string `yaml:"stripe_secret_key"`
		PaystackPrivateKey string `yaml:"paystack_private_key"`
		ProPlanPrice       int8   `yaml:"pro_plan_price"`
	}
)

func LoadEnv() error {
	pathStr, err := GetBasePath()
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
		fmt.Printf("env does not exists: %s", err.Error())
	}
	pathStr, err := GetBasePath()
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

// GetJournalEntryTypes returns all valid journal entry types
func GetJournalEntryTypes() []string {
	return []string{"morning", "evening", "wisdom_note"}
}

// GetDefaultTags returns default tags for the journal
func GetDefaultTags() []string {
	return []string{"Faith", "Family", "Focus", "Rest", "Growth", "Gratitude"}
}

// IsValidEntryType checks if the entry type is valid
func IsValidEntryType(entryType string) bool {
	validTypes := GetJournalEntryTypes()
	return slices.Contains(validTypes, entryType)
}

// TODO load env should not cause the app to crash
