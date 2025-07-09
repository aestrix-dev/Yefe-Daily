package middlewares

import (
	"net/http"

	"yefe_app/v1/internal/domain"
	"yefe_app/v1/pkg/logger"
	"yefe_app/v1/pkg/types"
	"yefe_app/v1/pkg/utils"
)

// AdminOnly middleware restricts access to admin users
func (m *AuthMiddleware) AdminOnly(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Get user from context (set by RequireAuth middleware)
		user, ok := r.Context().Value("user").(*domain.User)
		if !ok || user == nil {
			logger.Log.Warn("AdminOnly: User not found in context")
			m.handleAuthError(w, domain.ErrUnauthorized)
			return
		}

		// Check admin privileges
		if !user.IsAdmin() {
			logger.Log.Warnf("AdminOnly: Non-admin user '%s' attempted access", user.ID)

			// Log security event
			m.secEventRepo.LogSecurityEvent(r.Context(), user.ID, types.EventUnauthorizedAccess,
				r.Method, r.URL.Path, types.JSONMap{
					"attempted_route": r.URL.Path,
					"method":          r.Method,
				})

			utils.ErrorResponse(w, http.StatusForbidden, "Admin privileges required", nil)
			return
		}

		// Proceed to protected handler
		next.ServeHTTP(w, r)
	})
}
