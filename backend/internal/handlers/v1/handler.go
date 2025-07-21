package handlers

import (
	"context"
	"yefe_app/v1/internal/domain"
)

func getUserIDFromContext(ctx context.Context) string {
	// Implementation depends on your auth middleware
	return ctx.Value("user_id").(string)
}

func getUserFromContext(ctx context.Context) *domain.User {
	// Implementation depends on your auth middleware
	return ctx.Value("user").(*domain.User)
}
