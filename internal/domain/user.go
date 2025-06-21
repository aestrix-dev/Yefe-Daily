package domain

import (
	"time"
	"yefe_app/v1/internal/handlers/dto"

	"github.com/google/uuid"
)

type User struct {
	ID        uuid.UUID
	Name      string
	Email     string
	Password  string
	IsActive  bool
	CreatedAt time.Time
	UpdatedAt time.Time
}

type UserRepository interface {
	Create(user *User) error
	Update(id uuid.UUID) error
	GetUser(id uuid.UUID) User
	FindAll() ([]User, error)
}

type UserService interface {
	CreateUser(req dto.CreateUserRequest) error
	GetUser(id string) (*User, error)
	AuthenticateUser(email, password string) (*User, error)
}
