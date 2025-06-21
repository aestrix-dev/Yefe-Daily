package types

type HttpHander interface {
	Handle()
}

// Password security configuration
type PasswordConfig struct {
	Memory      uint32
	Iterations  uint32
	Parallelism uint8
	SaltLength  uint32
	KeyLength   uint32
}
