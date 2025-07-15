package service

import (
	"context"
	"fmt"
	"net/smtp"
	"strings"
	"sync"
	"time"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/utils"
)

// EmailServiceImpl implements EmailService with background processing
type EmailServiceImpl struct {
	config        utils.EmailConfig
	emailQueue    chan EmailJob
	backgroundSvc *BackgroundService
	workerCount   int
	isRunning     bool
	mu            sync.RWMutex
	logger        Logger
}

// EmailJob represents an email to be sent
type EmailJob struct {
	ID       string
	Request  dto.EmailRequest
	Attempts int
	MaxRetry int
	callback func(error)
}

// EmailWorker implements the Worker interface for background email processing
type EmailWorker struct {
	service *EmailServiceImpl
}

// NewEmailService creates a new email service with background processing
func NewEmailService(config utils.EmailConfig, logger Logger) *EmailServiceImpl {
	if logger == nil {
		logger = &DefaultLogger{}
	}

	if config.WorkerCount == 0 {
		config.WorkerCount = 2
	}
	if config.QueueSize == 0 {
		config.QueueSize = 1000
	}
	if config.RetryAttempts == 0 {
		config.RetryAttempts = 3
	}
	if config.RetryDelay == 0 {
		config.RetryDelay = 5 * time.Second
	}

	emailSvc := &EmailServiceImpl{
		config:      config,
		emailQueue:  make(chan EmailJob, config.QueueSize),
		workerCount: config.WorkerCount,
		logger:      logger,
	}

	// Create background service
	worker := &EmailWorker{service: emailSvc}
	bgConfig := DefaultServiceConfig("email-service")
	bgConfig.Logger = logger
	bgConfig.RestartOnPanic = true
	bgConfig.MaxRestartAttempts = 5
	bgConfig.RestartDelay = 10 * time.Second
	bgConfig.HealthCheckInterval = 5 * time.Minute

	emailSvc.backgroundSvc = NewBackgroundService(bgConfig, worker)

	return emailSvc
}

// Start starts the email service and background workers
func (e *EmailServiceImpl) Start() error {
	e.mu.Lock()
	defer e.mu.Unlock()

	if e.isRunning {
		return fmt.Errorf("email service is already running")
	}

	e.logger.Info("Starting email service with %d workers", e.workerCount)

	if err := e.backgroundSvc.Start(); err != nil {
		return fmt.Errorf("failed to start background service: %w", err)
	}

	e.isRunning = true
	e.logger.Info("Email service started successfully")
	return nil
}

// Stop stops the email service gracefully
func (e *EmailServiceImpl) Stop() error {
	e.mu.Lock()
	defer e.mu.Unlock()

	if !e.isRunning {
		return fmt.Errorf("email service is not running")
	}

	e.logger.Info("Stopping email service...")

	// Close the queue to signal workers to stop
	close(e.emailQueue)

	// Stop background service
	if err := e.backgroundSvc.Stop(); err != nil {
		e.logger.Error("Error stopping background service: %v", err)
		return err
	}

	e.isRunning = false
	e.logger.Info("Email service stopped successfully")
	return nil
}

// SendEmail queues an email for sending
func (e *EmailServiceImpl) SendEmail(ctx context.Context, req dto.EmailRequest) error {
	e.mu.RLock()
	defer e.mu.RUnlock()

	if !e.isRunning {
		return fmt.Errorf("email service is not running")
	}

	job := EmailJob{
		ID:       fmt.Sprintf("email-%d", time.Now().UnixNano()),
		Request:  req,
		Attempts: 0,
		MaxRetry: e.config.RetryAttempts,
	}

	select {
	case e.emailQueue <- job:
		e.logger.Debug("Email queued successfully: %s", job.ID)
		return nil
	case <-ctx.Done():
		return ctx.Err()
	default:
		return fmt.Errorf("email queue is full")
	}
}

// SendAdminInvitation sends an admin invitation email
func (e *EmailServiceImpl) SendAdminInvitation(ctx context.Context, req dto.AdminInvitationEmailResponse) error {
	// Build the invitation email content
	subject := fmt.Sprintf("Admin Invitation - %s", req.Role)

	htmlBody := e.buildAdminInvitationHTML(req)
	textBody := e.buildAdminInvitationText(req)

	emailReq := dto.EmailRequest{
		To:       []string{req.Email},
		Subject:  subject,
		Body:     textBody,
		HTMLBody: htmlBody,
	}

	return e.SendEmail(ctx, emailReq)
}
func (e *EmailServiceImpl) SendPaymentConfirmationEmail(ctx context.Context, req dto.PaymentConfirmationEmailData) error {
	// Build the invitation email content
	subject := fmt.Sprintf("Payment confitmation for Yefe Plus")

	htmlBody := e.buildPaymentConfirmationHTML(req)
	textBody := e.buildPaymentConfirmationText(req)
	fmt.Println(textBody)

	emailReq := dto.EmailRequest{
		To:       []string{req.Email},
		Subject:  subject,
		Body:     textBody,
		HTMLBody: htmlBody,
	}

	return e.SendEmail(ctx, emailReq)
}

// EmailWorker implementation for background processing
func (w *EmailWorker) Name() string {
	return "email-worker"
}

func (w *EmailWorker) Run(ctx context.Context) error {
	w.service.logger.Info("Email worker started")

	// Start multiple worker goroutines
	var wg sync.WaitGroup
	for i := 0; i < w.service.workerCount; i++ {
		wg.Add(1)
		go func(workerID int) {
			defer wg.Done()
			w.service.logger.Debug("Email worker %d started", workerID)
			w.processEmails(ctx, workerID)
		}(i)
	}

	wg.Wait()
	w.service.logger.Info("All email workers stopped")
	return nil
}

func (w *EmailWorker) HealthCheck(ctx context.Context) error {
	// Simple health check - verify SMTP connection
	serverAddr := fmt.Sprintf("%s:%s", w.service.config.SMTPHost, w.service.config.SMTPPort)
	auth := smtp.PlainAuth("", w.service.config.SMTPUsername, w.service.config.SMTPPassword, w.service.config.SMTPHost)

	// Try to connect and authenticate
	client, err := smtp.Dial(serverAddr)
	if err != nil {
		return fmt.Errorf("failed to connect to SMTP server: %w", err)
	}
	defer client.Close()

	if err := client.Auth(auth); err != nil {
		return fmt.Errorf("SMTP authentication failed: %w", err)
	}

	return nil
}

// processEmails processes emails from the queue
func (w *EmailWorker) processEmails(ctx context.Context, workerID int) {
	for {
		select {
		case <-ctx.Done():
			w.service.logger.Debug("Email worker %d stopping due to context cancellation", workerID)
			return
		case job, ok := <-w.service.emailQueue:
			if !ok {
				w.service.logger.Debug("Email worker %d stopping due to closed queue", workerID)
				return
			}

			w.service.logger.Debug("Worker %d processing email job: %s", workerID, job.ID)

			// Process the email
			err := w.sendEmailJob(job)
			if err != nil {
				w.service.logger.Error("Worker %d failed to send email %s: %v", workerID, job.ID, err)

				// Retry logic
				if job.Attempts < job.MaxRetry {
					job.Attempts++
					w.service.logger.Info("Retrying email %s (attempt %d/%d)", job.ID, job.Attempts, job.MaxRetry)

					// Wait before retry
					select {
					case <-time.After(w.service.config.RetryDelay):
						// Re-queue the job
						select {
						case w.service.emailQueue <- job:
						case <-ctx.Done():
							return
						default:
							w.service.logger.Error("Failed to re-queue email %s for retry", job.ID)
						}
					case <-ctx.Done():
						return
					}
				} else {
					w.service.logger.Error("Email %s failed after %d attempts, giving up", job.ID, job.MaxRetry)
				}
			} else {
				w.service.logger.Debug("Worker %d successfully sent email: %s", workerID, job.ID)
			}

			// Call callback if provided
			if job.callback != nil {
				job.callback(err)
			}
		}
	}
}

// sendEmailJob actually sends the email
func (w *EmailWorker) sendEmailJob(job EmailJob) error {
	// Create the email message
	message := w.service.buildEmailMessage(
		job.Request.To,
		job.Request.CC,
		job.Request.BCC,
		job.Request.Subject,
		job.Request.Body,
		job.Request.HTMLBody,
	)

	// Send the email
	return w.service.sendSMTPEmail(job.Request.To, message)
}

// buildEmailMessage creates the email message with proper headers
func (e *EmailServiceImpl) buildEmailMessage(to, cc, bcc []string, subject, body, htmlBody string) []byte {
	var message strings.Builder

	// Headers
	message.WriteString(fmt.Sprintf("From: %s <%s>\r\n", e.config.FromName, e.config.FromEmail))
	message.WriteString(fmt.Sprintf("To: %s\r\n", strings.Join(to, ", ")))

	if len(cc) > 0 {
		message.WriteString(fmt.Sprintf("Cc: %s\r\n", strings.Join(cc, ", ")))
	}

	if len(bcc) > 0 {
		message.WriteString(fmt.Sprintf("Bcc: %s\r\n", strings.Join(bcc, ", ")))
	}

	message.WriteString(fmt.Sprintf("Subject: %s\r\n", subject))
	message.WriteString("MIME-Version: 1.0\r\n")

	// If HTML body is provided, create multipart message
	if htmlBody != "" {
		boundary := fmt.Sprintf("boundary-%d", time.Now().Unix())
		message.WriteString(fmt.Sprintf("Content-Type: multipart/alternative; boundary=%s\r\n", boundary))
		message.WriteString("\r\n")

		// Plain text part
		message.WriteString(fmt.Sprintf("--%s\r\n", boundary))
		message.WriteString("Content-Type: text/plain; charset=UTF-8\r\n")
		message.WriteString("\r\n")
		message.WriteString(body)
		message.WriteString("\r\n")

		// HTML part
		message.WriteString(fmt.Sprintf("--%s\r\n", boundary))
		message.WriteString("Content-Type: text/html; charset=UTF-8\r\n")
		message.WriteString("\r\n")
		message.WriteString(htmlBody)
		message.WriteString("\r\n")

		message.WriteString(fmt.Sprintf("--%s--\r\n", boundary))
	} else {
		// Plain text only
		message.WriteString("Content-Type: text/plain; charset=UTF-8\r\n")
		message.WriteString("\r\n")
		message.WriteString(body)
	}

	return []byte(message.String())
}

// sendSMTPEmail sends the email using SMTP
func (e *EmailServiceImpl) sendSMTPEmail(to []string, message []byte) error {
	// Create SMTP authentication
	auth := smtp.PlainAuth("", e.config.SMTPUsername, e.config.SMTPPassword, e.config.SMTPHost)

	// Create the server address
	serverAddr := fmt.Sprintf("%s:%s", e.config.SMTPHost, e.config.SMTPPort)

	// Send the email
	err := smtp.SendMail(serverAddr, auth, e.config.FromEmail, to, message)
	if err != nil {
		return fmt.Errorf("failed to send email: %w", err)
	}

	return nil
}

// buildAdminInvitationHTML creates the HTML content for admin invitation
func (e *EmailServiceImpl) buildAdminInvitationHTML(req dto.AdminInvitationEmailResponse) string {
	return fmt.Sprintf(`
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Admin Invitation</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f9f9f9; }
        .button { 
            display: inline-block; 
            padding: 12px 24px; 
            background-color: #4CAF50; 
            color: white; 
            text-decoration: none; 
            border-radius: 4px; 
            margin: 20px 0;
        }
        .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Admin Invitation</h1>
        </div>
        <div class="content">
            <p>Hello,</p>
            <p>You have been invited to join as an admin with the role of <strong>%s</strong>.</p>
            <p>Please click the button below to accept your invitation:</p>
            <a href="%s" class="button">Accept Invitation</a>
            <p>Or copy and paste this link into your browser:</p>
            <p><a href="%s">%s</a></p>
            <p>This link is only valid for 3 days </p>
            <p>If you didn't expect this invitation, please ignore this email.</p>
        </div>
        <div class="footer">
            <p>This is an automated message. Please do not reply to this email.</p>
        </div>
    </div>
</body>
</html>`,
		req.Role,
		req.InvitationLink,
		req.InvitationLink,
		req.InvitationLink,
	)
}

// buildAdminInvitationText creates the plain text content for admin invitation
func (e *EmailServiceImpl) buildAdminInvitationText(req dto.AdminInvitationEmailResponse) string {
	return fmt.Sprintf(`
Admin Invitation

Hello,

You have been invited to join as an admin with the role of %s.

Please click the link below to accept your invitation: %s.

This invitation is only active for 3 days.

If you didn't expect this invitation, please ignore this email.

---
This is an automated message. Please do not reply to this email.
`,
		req.Role,
		req.InvitationLink,
	)
}

// buildPaymentConfirmationHTML creates the HTML content for a payment confirmation email
func (e *EmailServiceImpl) buildPaymentConfirmationHTML(req dto.PaymentConfirmationEmailData) string {
	var b strings.Builder

	b.WriteString(`<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Payment Confirmation</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f9f9f9; }
        .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
        .summary-table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        .summary-table td { padding: 8px; border-bottom: 1px solid #ddd; }
        .summary-table td.label { font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Payment Confirmation</h1>
        </div>
        <div class="content">
`)

	// Dynamic content
	b.WriteString(fmt.Sprintf("<p>Hello %s,</p>\n", req.Name))
	b.WriteString("<p>Thank you for your payment. We’ve successfully processed your transaction.</p>\n")

	b.WriteString(`<table class="summary-table">`)
	b.WriteString(fmt.Sprintf("<tr><td class=\"label\">Amount:</td><td>%s %d</td></tr>\n", req.Currency, req.Amount))
	b.WriteString(fmt.Sprintf("<tr><td class=\"label\">Payment ID:</td><td>%s</td></tr>\n", req.PaymentID))
	b.WriteString(fmt.Sprintf("<tr><td class=\"label\">Date:</td><td>%s</td></tr>\n", req.Date.Format("January 2, 2006 at 3:04 PM")))
	b.WriteString(fmt.Sprintf("<tr><td class=\"label\">Payment Method:</td><td>%s</td></tr>\n", req.PaymentMethod))
	b.WriteString(fmt.Sprintf("<tr><td class=\"label\">Status:</td><td>%s</td></tr>\n", req.Status))
	b.WriteString("</table>\n")

	b.WriteString(`<p>If you have any questions or need a receipt, please contact our support team.</p>
        </div>
        <div class="footer">
            <p>This is an automated message. Please do not reply to this email.</p>
        </div>
    </div>
</body>
</html>`)

	return b.String()
}

// buildPaymentConfirmationText creates the plain text content for a payment confirmation email
func (e *EmailServiceImpl) buildPaymentConfirmationText(req dto.PaymentConfirmationEmailData) string {
	return fmt.Sprintf(`
Payment Confirmation

Hello %s,

Thank you for your payment. We’ve successfully processed your transaction.

Amount: %s %d
Payment ID: %s
Date: %s
Payment Method: %s
Status: %s

If you have any questions or need a receipt, please contact our support team.

---
This is an automated message. Please do not reply to this email.
`,
		req.Name,
		req.Currency,
		req.Amount,
		req.PaymentID,
		req.Date.Format("January 2, 2006 at 3:04 PM"),
		req.PaymentMethod,
		req.Status,
	)
}

// GetStats returns email service statistics
func (e *EmailServiceImpl) GetStats() ServiceStats {
	if e.backgroundSvc != nil {
		return e.backgroundSvc.Stats()
	}
	return ServiceStats{}
}

// IsRunning returns true if the service is running
func (e *EmailServiceImpl) IsRunning() bool {
	e.mu.RLock()
	defer e.mu.RUnlock()
	return e.isRunning
}

// Example usage with service manager:
