package utils

import (
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"
	"yefe_app/v1/internal/domain"

	"github.com/golang-jwt/jwt"
)

// Response helpers
type APIResponse struct {
	Success   bool        `json:"success"`
	Message   string      `json:"message"`
	Data      interface{} `json:"data,omitempty"`
	Error     interface{} `json:"error,omitempty"`
	RequestID string      `json:"request_id,omitempty"`
	Timestamp string      `json:"timestamp"`
}

func GetClientIP(r *http.Request) string {
	// Check X-Forwarded-For header first (for proxies)
	forwarded := r.Header.Get("X-Forwarded-For")
	if forwarded != "" {
		return strings.Split(forwarded, ",")[0]
	}

	// Check X-Real-IP header
	realIP := r.Header.Get("X-Real-IP")
	if realIP != "" {
		return realIP
	}

	// Fall back to RemoteAddr
	return strings.Split(r.RemoteAddr, ":")[0]
}

func HandleDomainError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, domain.ErrUserNotFound):
		ErrorResponse(w, http.StatusNotFound, "User not found", nil)

	case errors.Is(err, domain.ErrInvalidPlanType),
		errors.Is(err, domain.ErrInvalidUserStatus),
		errors.Is(err, domain.ErrInvalidPlanTransition):
		ErrorResponse(w, http.StatusBadRequest, err.Error(), nil)

	case errors.Is(err, domain.ErrUserAlreadyHasPlan):
		ErrorResponse(w, http.StatusConflict, err.Error(), nil)

	case errors.Is(err, domain.ErrPlanUpdateConflict):
		ErrorResponse(w, http.StatusConflict, "Plan update in progress", nil)

	case errors.Is(err, domain.ErrPremiumPlanRequired):
		ErrorResponse(w, http.StatusForbidden, "Premium plan required", nil)

	// Existing cases
	case errors.Is(err, domain.ErrUserInactive),
		errors.Is(err, domain.ErrAccountInactive):
		ErrorResponse(w, http.StatusForbidden, "Account is inactive", nil)

	case errors.Is(err, domain.ErrAccountLocked):
		ErrorResponse(w, http.StatusLocked, "Account is locked", nil)

	case errors.Is(err, domain.ErrEmailNotVerified):
		ErrorResponse(w, http.StatusForbidden, "Email not verified", nil)

	case errors.Is(err, domain.ErrWeakPassword):
		ErrorResponse(w, http.StatusBadRequest, "Password too weak", nil)

	case errors.Is(err, domain.ErrEmailAlreadyExists),
		errors.Is(err, domain.ErrUsernameAlreadyExists):
		ErrorResponse(w, http.StatusConflict, "Resource already exists", nil)

	case errors.Is(err, domain.ErrInvalidToken):
		ErrorResponse(w, http.StatusUnauthorized, "Invalid token", nil)

	case errors.Is(err, domain.ErrRateLimitExceeded):
		ErrorResponse(w, http.StatusTooManyRequests, "Too many requests", nil)

	default:
		ErrorResponse(w, http.StatusInternalServerError, "Internal server error", nil)
	}
}

// SuccessResponse sends a successful JSON response
func SuccessResponse(w http.ResponseWriter, statusCode int, message string, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)

	response := APIResponse{
		Success:   true,
		Message:   message,
		Data:      data,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}

	// Add request ID if available from context
	if reqID := w.Header().Get("X-Request-Id"); reqID != "" {

		response.RequestID = reqID
	}

	json.NewEncoder(w).Encode(response)
}

// ErrorResponse sends an error JSON response
func ErrorResponse(w http.ResponseWriter, statusCode int, message string, errorData interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)

	response := APIResponse{
		Success:   false,
		Message:   message,
		Error:     errorData,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}

	// Add request ID if available from context
	if reqID := w.Header().Get("X-Request-Id"); reqID != "" {
		response.RequestID = reqID
	}

	json.NewEncoder(w).Encode(response)
}

// Additional helper for JSON responses with custom status
func JSONResponse(w http.ResponseWriter, statusCode int, payload interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(payload)
}

// Helper for validation error responses
func ValidationErrorResponse(w http.ResponseWriter, err error) {
	ErrorResponse(w, http.StatusBadRequest, "Validation failed", formatValidationErrors(err))
}

// Helper for internal server error
func InternalServerError(w http.ResponseWriter, err error) {
	// Log the actual error for debugging
	fmt.Printf("Internal server error: %v\n", err)
	ErrorResponse(w, http.StatusInternalServerError, "Internal server error", nil)
}

// Helper function to extract session ID from JWT token
func ExtractSessionIDFromToken(tokenString, jwtSecret string) (string, error) {
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (any, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		secret, err := hex.DecodeString(jwtSecret)
		if err != nil {
			return nil, fmt.Errorf("invalid JWT secret encoding: %w", err)
		}
		return secret, nil
	})

	if err != nil {
		return "", err
	}
	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		if sessionID, exists := claims["session_id"]; exists {
			if sessionIDStr, ok := sessionID.(string); ok {
				return sessionIDStr, nil
			}
		}
	}

	return "", domain.ErrInvalidToken
}
