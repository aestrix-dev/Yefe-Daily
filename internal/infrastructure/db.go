package infrastructure

import (
	"fmt"
	"yefe_app/v1/internal/infrastructure/db/models"
	"yefe_app/v1/pkg/utils"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func NewDB(cfg utils.DBSettings) (*gorm.DB, error) {
	p := &postgresPersistence{cfg}
	return p.connect()
}

type postgresPersistence struct {
	config utils.DBSettings
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
	err = db.AutoMigrate(models.UserModel{})
	if err != nil {
		return nil, err
	}
	return db, nil
}

// TODO add a migration tool like go migrate
