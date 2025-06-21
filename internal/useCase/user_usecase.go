package usecase

import (
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

func NewUserUsecase(r domain.UserRepository) *userService {
	return &userService{repo: r}
}

type userService struct {
	repo domain.UserRepository
}

func (s *userService) CreateUser(req dto.CreateUserRequest) error {
	if existingUser, _ := s.repo.GetByEmail(req.Email); existingUser != nil {
		return nil, domain.ErrUserExists
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	// Create user entity
	user := &domain.User{
		ID:        uuid.New().String(),
		Email:     req.Email,
		Name:      req.Name,
		Password:  string(hashedPassword),
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
		IsActive:  true,
	}

	// Validate user
	if err := user.Validate(); err != nil {
		return nil, err
	}

	// Save user
	if err := s.repo.Create(user); err != nil {
		return err
	}

	return nil
}
