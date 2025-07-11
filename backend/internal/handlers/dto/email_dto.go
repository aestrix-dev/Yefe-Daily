package dto

import "time"

type EmailRequest struct {
	To       []string `json:"to"`
	CC       []string `json:"cc,omitempty"`
	BCC      []string `json:"bcc,omitempty"`
	Subject  string   `json:"subject"`
	Body     string   `json:"body"`
	HTMLBody string   `json:"html_body,omitempty"`
}

type AdminInvitationEmailRequest struct {
	Email           string    `json:"email"`
	Role            string    `json:"role"`
	InvitedBy       string    `json:"invited_by"`
	InvitationToken string    `json:"invitation_token"`
	InvitationLink  string    `json:"invitation_link"`
	ExpiresAt       time.Time `json:"expires_at"`
}
