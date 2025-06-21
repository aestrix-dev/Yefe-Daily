package models

import (
	"yefe_app/v1/internal/domain"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type UserModel struct {
	gorm.Model
	ID       uuid.UUID `gorm:"primaryKey"`
	Email    string `gorm:"uniqueIndex"`
	Name     string
	Password string
	IsActive bool
}

func (UserModel) TableName() string {
	return "users"
}

func (u *UserModel) ToDomain() *domain.User {
	return &domain.User{
		ID:        u.ID,
		Email:     u.Email,
		Name:      u.Name,
		Password:  u.Password,
		IsActive:  u.IsActive,
		CreatedAt: u.CreatedAt,
		UpdatedAt: u.UpdatedAt,
	}
}

// FromDomain converts domain entity to GORM model
func (u *UserModel) FromDomain(user *domain.User) {
	u.ID = user.ID
	u.Email = user.Email
	u.Name = user.Name
	u.Password = user.Password
	u.IsActive = user.IsActive
}
