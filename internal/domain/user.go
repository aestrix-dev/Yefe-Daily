package domain

import "github.com/google/uuid"

type User struct {
	ID        uuid.UUID
	FirstName string
	LastName  string
	UserName  string
	Email     string
}

type UserRepository interface {
	Create(user *User) error
	Update(id uuid.UUID) error
	GetUser(id uuid.UUID) User
	FindAll() ([]User, error)
}
