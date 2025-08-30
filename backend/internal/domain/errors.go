package domain

import "errors"

// Authentication & Authorization Errors
var (
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrUserNotFound       = errors.New("user not found")
	ErrUserInactive       = errors.New("user inactive")
	ErrAccountLocked      = errors.New("account is locked")
	ErrAccountInactive    = errors.New("account is inactive")
	ErrEmailNotVerified   = errors.New("email not verified")
	ErrMissingAuthHeader  = errors.New("authorization header not found")
	ErrInvalidAuthHeader  = errors.New("invalid authorization header")
	ErrInvalidToken       = errors.New("invalid or expired token")
	ErrUnauthorized       = errors.New("unauthorized access")
	ErrHourError          = errors.New("Hour cannot be less than 0 and greater then 12")
	ErrMinuteError          = errors.New("Minute cannot be less than 0 and greater then 12")
)

// User Management Errors
var (
	ErrEmailAlreadyExists    = errors.New("email already exists")
	ErrUsernameAlreadyExists = errors.New("user already exists")
	ErrWeakPassword          = errors.New("password does not meet requirements")
	ErrInvalidUserStatus     = errors.New("invalid user status")
)

// Session Errors
var (
	ErrSessionNotFound        = errors.New("session not found")
	ErrSessionInactive        = errors.New("session inactive")
	ErrSessionExpired         = errors.New("session expired")
	ErrSessionAlreadyInactive = errors.New("session already inactive")
)

// Rate Limiting Errors
var (
	ErrRateLimitExceeded = errors.New("rate limit exceeded")
)

// Journal/Content Errors
var (
	ErrEntryNotFound    = errors.New("entry not found")
	ErrInvalidEntryType = errors.New("invalid entry type")
	ErrEmptyContent     = errors.New("content cannot be empty")
	ErrDuplicateEntry   = errors.New("duplicate entry")
)

// Subscription/Plan Errors
var (
	ErrInvalidPlanType       = errors.New("invalid plan type")
	ErrUserAlreadyHasPlan    = errors.New("user already has this plan")
	ErrPlanUpdateConflict    = errors.New("cannot change plan during pending update")
	ErrPremiumPlanRequired   = errors.New("premium plan required")
	ErrInvalidPlanTransition = errors.New("invalid plan transition")
)

// Music Catalog Errors
var (
	ErrSongNotFound         = errors.New("song not found")
	ErrInvalidAccessLevel   = errors.New("invalid access level")
	ErrMusicMetadataMissing = errors.New("music metadata missing")
	ErrInvalidMusicFormat   = errors.New("invalid music format")
)

// API/Request Errors
var (
	ErrInvalidRequest      = errors.New("invalid request")
	ErrResourceNotFound    = errors.New("resource not found")
	ErrConflict            = errors.New("resource conflict")
	ErrUnprocessableEntity = errors.New("unprocessable entity")
)

// Challenge Errors
var (
	ErrChallengeNotFound       = errors.New("challenge not found")
	ErrChallengeAlreadyCompleted = errors.New("challenge already completed")
	ErrNotTodaysChallenge      = errors.New("challenge is not for today")
)

// Helper functions for error classification
func IsNotFoundError(err error) bool {
	return errors.Is(err, ErrUserNotFound) ||
		errors.Is(err, ErrSessionNotFound) ||
		errors.Is(err, ErrEntryNotFound) ||
		errors.Is(err, ErrSongNotFound) ||
		errors.Is(err, ErrResourceNotFound)
}

func IsAuthorizationError(err error) bool {
	return errors.Is(err, ErrUnauthorized) ||
		errors.Is(err, ErrInvalidToken) ||
		errors.Is(err, ErrMissingAuthHeader) ||
		errors.Is(err, ErrInvalidAuthHeader) ||
		errors.Is(err, ErrInvalidCredentials)
}

func IsConflictError(err error) bool {
	return errors.Is(err, ErrEmailAlreadyExists) ||
		errors.Is(err, ErrUsernameAlreadyExists) ||
		errors.Is(err, ErrDuplicateEntry) ||
		errors.Is(err, ErrUserAlreadyHasPlan) ||
		errors.Is(err, ErrPlanUpdateConflict) ||
		errors.Is(err, ErrConflict)
}
