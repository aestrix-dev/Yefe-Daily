package infrastructure

import (
	"fmt"
	"log"
	"time"
	"yefe_app/v1/internal/infrastructure/db/models"
	"yefe_app/v1/pkg/utils"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func NewDB(cfg utils.DBSettings) (*gorm.DB, error) {
	p := &postgresPersistence{config: cfg, MaxOpenConns: 5, MaxIdleConns: 2, ConnMaxLifetime: 10 * time.Hour}
	return p.connect()
}

type postgresPersistence struct {
	config utils.DBSettings
	//SSLMode         string
	MaxOpenConns    int
	MaxIdleConns    int
	ConnMaxLifetime time.Duration
}

func (p postgresPersistence) connectionString() string {
	return fmt.Sprintf(
		"host=%v port=%v user=%v dbname=%v password=%v sslmode=disable TimeZone=Africa/Lagos",
		p.config.Host, p.config.Port, p.config.UserName, p.config.DataBase, p.config.Password)
}

func (p postgresPersistence) connect() (*gorm.DB, error) {
	connectionDSN := p.connectionString()
	db, err := gorm.Open(postgres.New(
		postgres.Config{
			DSN:                  connectionDSN,
			PreferSimpleProtocol: true}), &gorm.Config{})
	if err != nil {
		return nil, err
	}

	if err != nil {
		return nil, err
	}

	sqlDB, err := db.DB()
	if err != nil {
		return nil, err
	}

	sqlDB.SetMaxOpenConns(p.MaxOpenConns)
	sqlDB.SetMaxIdleConns(p.MaxIdleConns)
	sqlDB.SetConnMaxLifetime(p.ConnMaxLifetime)
	err = autoMigrate(db)
	if err != nil {
		return nil, err
	}
	err = createIndexes(db)
	if err != nil {
		return nil, err
	}
	return db, nil
}
func autoMigrate(db *gorm.DB) error {
	return db.AutoMigrate(
		&models.User{},
		&models.UserProfile{},
		&models.Session{},
		&models.SecurityEvent{},
		&models.LoginAttempt{},
		&models.TrustedDevice{},
		&models.Role{},
		&models.Permission{},
		&models.UserRole{},
		&models.RolePermission{},
	)
}

// Create indexes for optimal performance
func createIndexes(db *gorm.DB) error {
	indexes := []string{
		"CREATE INDEX IF NOT EXISTS idx_users_email_active ON users(email, is_active)",
		"CREATE INDEX IF NOT EXISTS idx_users_username_active ON users(username, is_active)",
		"CREATE INDEX IF NOT EXISTS idx_sessions_user_active ON sessions(user_id, is_active)",
		"CREATE INDEX IF NOT EXISTS idx_sessions_expires_active ON sessions(expires_at, is_active)",
		"CREATE INDEX IF NOT EXISTS idx_security_events_user_type ON security_events(user_id, event_type)",
		"CREATE INDEX IF NOT EXISTS idx_security_events_created_severity ON security_events(created_at, severity)",
		"CREATE INDEX IF NOT EXISTS idx_login_attempts_ip_created ON login_attempts(ip_address, created_at)",
		"CREATE INDEX IF NOT EXISTS idx_rate_limits_key_expires ON rate_limit_entries(key, expires_at)",
	}

	for _, index := range indexes {
		if err := db.Exec(index).Error; err != nil {
			log.Printf("Failed to create index: %v", err)
		}
	}

	return nil
}

// TODO add a migration tool like go migrate
