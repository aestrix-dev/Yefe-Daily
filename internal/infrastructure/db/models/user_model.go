package models

type UserModel struct {
	ID       uint `gorm:"primaryKey"`
	Name     string
	Username string `gorm:"uniqueIndex"`
	Plan     string
}
