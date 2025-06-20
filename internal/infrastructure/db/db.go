package persistence

import (
	"fmt"

	"github.com/yefe_app/server/pkg/utils"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func NewDB(cfg utils.DBSettings) *postgresPersistence {
	return &postgresPersistence{cfg}
}

type postgresPersistence struct {
	config utils.DBSettings
}

func (p postgresPersistence) connectionString() string {
	return fmt.Sprintf(
		"host=%v port=%v user=%v dbname=%v password=%v sslmode=disable TimeZone=Africa/Lagos",
		p.config.Host, p.config.Port, p.config.UserName, p.config.DataBase, p.config.Password)
}

func (p postgresPersistence) Connect() *gorm.DB {
	connectionDSN := p.connectionString()
	db, err := gorm.Open(postgres.New(
		postgres.Config{
			DSN:                  connectionDSN,
			PreferSimpleProtocol: true}), &gorm.Config{})
	if err != nil {
		panic(err)
	}
	return db
}
