package domain

import "errors"

var (
	ErrUserInactive           = errors.New("User inactive")
	ErrUserNotFound           = errors.New("user not found")
	ErrInvalidCredentials     = errors.New("invalid credentials")
	ErrAccountLocked          = errors.New("account is locked")
	ErrAccountInactive        = errors.New("account is inactive")
	ErrEmailNotVerified       = errors.New("email not verified")
	ErrWeakPassword           = errors.New("password does not meet requirements")
	ErrEmailAlreadyExists     = errors.New("email already exists")
	ErrUsernameAlreadyExists  = errors.New("username already exists")
	ErrInvalidToken           = errors.New("invalid or expired token")
	ErrRateLimitExceeded      = errors.New("rate limit exceeded")
	ErrSessionNotFound        = errors.New("User session not found")
	ErrSessionAlreadyInactive = errors.New("Session already inactive")
	ErrSessionInactive        = errors.New("Session already inactive")
	ErrSessionExpired         = errors.New("Session expired")
	ErrMissingAuthHeader      = errors.New("Auth Header not found")
	ErrInvalidAuthHeader      = errors.New("Invalid Auth header")
)
