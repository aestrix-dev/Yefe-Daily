package middlewares

import (
	"context"
	"net/http"
	"strings"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/pkg/logger"
	"yefe_app/v1/pkg/types"
	"yefe_app/v1/pkg/utils"
)

type AuthMiddleware struct {
	jwtSecret    string
	sessionRepo  domain.SessionRepository
	userRepo     domain.UserRepository
	secEventRepo domain.SecurityEventRepository
}

func NewAuthMiddleware(
	jwtSecret string,
	sessionRepo domain.SessionRepository,
	userRepo domain.UserRepository,
	secEventRepo domain.SecurityEventRepository,
) *AuthMiddleware {
	return &AuthMiddleware{
		jwtSecret:    jwtSecret,
		sessionRepo:  sessionRepo,
		userRepo:     userRepo,
		secEventRepo: secEventRepo,
	}
}

// RequireAuth middleware - requires valid authentication
func (m *AuthMiddleware) RequireAuth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodOptions {
			next.ServeHTTP(w, r)
			return
		}
		user, session, err := m.authenticateRequest(r)
		if err != nil {
			m.handleAuthError(w, err)
			return
		}

		// Add user and session to context
		ctx := r.Context()
		ctx = context.WithValue(ctx, "user", user)
		ctx = context.WithValue(ctx, "session", session)
		ctx = context.WithValue(ctx, "user_id", user.ID)
		ctx = context.WithValue(ctx, "session_id", session.ID)

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// OptionalAuth middleware - authentication is optional
func (m *AuthMiddleware) OptionalAuth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		user, session, err := m.authenticateRequest(r)

		ctx := r.Context()
		if err == nil {
			// Add user and session to context if authentication successful
			ctx = context.WithValue(ctx, "user", user)
			ctx = context.WithValue(ctx, "session", session)
			ctx = context.WithValue(ctx, "user_id", user.ID)
			ctx = context.WithValue(ctx, "session_id", session.ID)
		}

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// authenticateRequest performs the actual authentication logic
func (m *AuthMiddleware) authenticateRequest(r *http.Request) (*domain.User, *domain.Session, error) {
	// Extract token from Authorization header
	token, err := m.extractTokenFromHeader(r)
	if err != nil {
		return nil, nil, err
	}

	// Parse and validate JWT
	sessionID, err := utils.ExtractSessionIDFromToken(token, m.jwtSecret)
	if err != nil {
		logger.Log.WithError(err).Error("JWT Token error")
		return nil, nil, domain.ErrInvalidToken
	}

	// Get session from database
	session, err := m.sessionRepo.GetByID(r.Context(), sessionID)
	if err != nil || session == nil {
		logger.Log.WithError(err).Errorf("Session not found: ", sessionID)
		return nil, nil, domain.ErrSessionNotFound
	}

	// Check if session is active
	if !session.IsActive {
		logger.Log.Errorf("Session %s inactive", sessionID)
		return nil, nil, domain.ErrSessionInactive
	}

	user, err := m.userRepo.GetByID(r.Context(), session.UserID)
	if err != nil || user == nil {
		return nil, nil, domain.ErrUserNotFound
	}

	// Check if user is active
	user_active := user.IsActive
	if !user_active {
		m.secEventRepo.LogSecurityEvent(r.Context(), user.ID, types.EventAuthFailed, "", "", types.JSONMap{
			"reason": "user_inactive",
		})
		return nil, nil, domain.ErrUserInactive
	}

	// Check if account is locked
	if user.AccountLockedUntil != nil && time.Now().Before(*user.AccountLockedUntil) {
		m.secEventRepo.LogSecurityEvent(r.Context(), user.ID, types.EventAuthFailed, "", "", types.JSONMap{
			"reason": "account_locked",
		})
		return nil, nil, domain.ErrAccountLocked
	}

	return user, session, nil
}

// extractTokenFromHeader extracts Bearer token from Authorization header
func (m *AuthMiddleware) extractTokenFromHeader(r *http.Request) (string, error) {
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" {
		return "", domain.ErrMissingAuthHeader
	}

	// Check if it's a Bearer token
	if !strings.HasPrefix(authHeader, "Bearer ") {
		return "", domain.ErrInvalidAuthHeader
	}

	// Extract token
	token := strings.TrimPrefix(authHeader, "Bearer ")
	if token == "" {
		return "", domain.ErrInvalidAuthHeader
	}

	return token, nil
}

// handleAuthError handles authentication errors
func (m *AuthMiddleware) handleAuthError(w http.ResponseWriter, err error) {
	w.Header().Set("Content-Type", "application/json")

	switch err {
	case domain.ErrMissingAuthHeader, domain.ErrInvalidAuthHeader:
		w.WriteHeader(http.StatusUnauthorized)
		w.Write([]byte(`{"error": "missing or invalid authorization header"}`))
	case domain.ErrInvalidToken:
		w.WriteHeader(http.StatusUnauthorized)
		w.Write([]byte(`{"error": "invalid token"}`))
	case domain.ErrSessionNotFound, domain.ErrSessionInactive, domain.ErrSessionExpired:
		w.WriteHeader(http.StatusUnauthorized)
		w.Write([]byte(`{"error": "session invalid or expired"}`))
	case domain.ErrUserNotFound, domain.ErrUserInactive:
		w.WriteHeader(http.StatusUnauthorized)
		w.Write([]byte(`{"error": "user not found or inactive"}`))
	case domain.ErrAccountLocked:
		w.WriteHeader(http.StatusLocked)
		w.Write([]byte(`{"error": "account is locked"}`))
	default:
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(`{"error": "internal server error"}`))
	}
}
