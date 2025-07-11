package domain

import (
	"context"
	"yefe_app/v1/internal/handlers/dto"
)

type EmailService interface {
	// Admin invitation emails
	SendAdminInvitation(ctx context.Context, req dto.AdminInvitationEmailResponse) error

	// General email operations
	SendEmail(ctx context.Context, req dto.EmailRequest) error
	//SendBulkEmail(ctx context.Context, requests []EmailRequest) error

	// Template-based emails
	//SendTemplateEmail(ctx context.Context, req TemplateEmailRequest) error

	// Email verification and notifications
	//SendEmailVerification(ctx context.Context, email string, token string) error
	//SendPasswordReset(ctx context.Context, email string, token string) error
	//SendWelcomeEmail(ctx context.Context, email string, userName string) error
}
