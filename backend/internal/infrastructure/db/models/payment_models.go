package models

import "time"

type Payment struct {
	ID               string     `json:"id" gorm:"primaryKey"`
	UserID           string     `json:"user_id" gorm:"not null"`
	FromPackageID    string     `json:"from_package_id"`
	ToPackageID      string     `json:"to_package_id" gorm:"not null"`
	Amount           int64      `json:"amount" gorm:"not null"`
	Currency         string     `json:"currency" gorm:"default:usd"`
	Status           string     `json:"status" gorm:"default:pending"`
	PaymentIntentID  string     `json:"payment_intent_id"`
	StripeCustomerID string     `json:"stripe_customer_id"`
	PaymentMethod    string     `json:"payment_method"`
	ProcessedAt      *time.Time `json:"processed_at"`
	CreatedAt        time.Time  `json:"created_at"`
	UpdatedAt        time.Time  `json:"updated_at"`
}

type UserSubscription struct {
	ID          uint      `json:"id" gorm:"primaryKey"`
	UserID      uint      `json:"user_id" gorm:"not null;uniqueIndex"`
	Status      string    `json:"status" gorm:"default:active"`
	StartDate   time.Time `json:"start_date"`
	EndDate     time.Time `json:"end_date"`
	StripeSubID string    `json:"stripe_subscription_id"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}
