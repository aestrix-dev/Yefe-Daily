package dto

import "github.com/google/uuid"

type CreateUserRequest struct {
	Name             string `json:"first_name"`
	Email            string `json:"email"`
	Password         string `json:"password"`
	Confirm_Password string `json:"Confirm_Password"`
}

type UserResponse struct {
	ID    uuid.UUID
	Name  string `json:"first_name"`
	Email string `json:"email"`
	Plan  string `json:"plan"`
}
