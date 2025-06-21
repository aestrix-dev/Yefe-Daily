package repository

import (
	"yefe_app/v1/internal/domain"

	"gorm.io/gorm"
)

type userGormRepository struct {
	db *gorm.DB
}

func NewUserGormRepository(db *gorm.DB) *userGormRepository {
	return &userGormRepository{db: db}
}

func (r *userGormRepository) Create(user domain.User) {}
