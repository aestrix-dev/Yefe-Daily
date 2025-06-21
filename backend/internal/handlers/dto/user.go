package dto

// Request/Response DTOs
type RegisterRequest struct {
	Email           string `json:"email" validate:"required,email"`
	Name            string `json:"Name" validate:"required,min=3,max=50"`
	Password        string `json:"password" validate:"required,min=8"`
	ConfirmPassword string `json:"confirm_password" validate:"required,eqfield=Password"`
	IPAddress       string `json:"-"`
	UserAgent       string `json:"-"`
}

type LoginRequest struct {
	EmailOrUsername string `json:"email_or_username" validate:"required"`
	Password        string `json:"password" validate:"required"`
	TwoFactorCode   string `json:"two_factor_code,omitempty"`
	IPAddress       string `json:"-"`
	UserAgent       string `json:"-"`
}

type LoginResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int64  `json:"expires_in"`
}
