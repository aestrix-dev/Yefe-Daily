package handlers

import "context"

func getUserIDFromContext(ctx context.Context) string {
	// Implementation depends on your auth middleware
	return ctx.Value("user_id").(string)
}
