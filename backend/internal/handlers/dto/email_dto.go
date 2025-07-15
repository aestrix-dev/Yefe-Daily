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
	Email string `json:"email"`
	Role  string `json:"role"`
}

type AdminInvitationEmailResponse struct {
	AdminInvitationEmailRequest
	InvitationLink string `json:"invitation_link"`
}

type PaymentConfirmationEmailData struct {
	Name          string
	Amount        int8
	Currency      string
	PaymentID     string
	Date          time.Time
	PaymentMethod string
	Status        string
	Email         string
}
