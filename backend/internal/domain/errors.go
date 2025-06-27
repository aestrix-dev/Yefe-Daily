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

	ErrEntryNotFound    = errors.New("journal entry not found")
	ErrUnauthorized     = errors.New("unauthorized access to journal entry")
	ErrInvalidEntryType = errors.New("invalid entry type")
	ErrEmptyContent     = errors.New("journal entry content cannot be empty")
	ErrDuplicateEntry   = errors.New("entry for this type already exists today")
)
