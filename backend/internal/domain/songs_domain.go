package domain

// Song represents the core music track entity in our domain
type Song struct {
	ID          string `json:"uuid"`
	Title       string `json:"title"`
	Feel        string `json:"feel"`
	Description string `json:"description"`
	Genre       string `json:"genre"`
	Length      string `json:"length"` // Format: "mm:ss"
	AccessLevel string `json:"access"` // "free" or "pro"
	DownloadURL string `json:"download_url"`
}

type MusicCatalog struct {
	TotalPieces int    `json:"total_pieces"`
	FreeCount   int    `json:"free_count"`
	Pieces      []Song `json:"pieces"`
}

// SongRepository defines the interface for song persistence
type SongRepository interface {
	FindAll() ([]Song, error)
	FindByID(id string) (*Song, error)
	FindByAccessLevel(accessLevel string) ([]Song, error)
	FindByMood(mood string) ([]Song, error)
}

type SongUseCase interface {
	GetSongs(userType UserType) ([]Song, error)
	GetSongDetails(songID string, userType UserType) (*Song, error)
	GetSongsByMood(mood string, userType UserType) ([]Song, error)
}
