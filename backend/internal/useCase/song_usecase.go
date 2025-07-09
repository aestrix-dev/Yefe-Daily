package usecase

import "yefe_app/v1/internal/domain"

// MusicUseCase implements the business logic
type MusicUseCase struct {
	repo domain.SongRepository
}

// NewMusicUseCase creates a new use case instance
func NewMusicUseCase(repo domain.SongRepository) domain.SongUseCase {
	return &MusicUseCase{repo: repo}
}

// GetSongs retrieves songs based on user type
func (uc *MusicUseCase) GetSongs(userType domain.UserType) ([]domain.Song, error) {
	switch userType {
	case domain.FreeUser:
		return uc.repo.FindByAccessLevel("free")
	case domain.ProUser:
		return uc.repo.FindAll()
	default:
		return nil, domain.ErrUserNotFound
	}
}

// GetSongDetails returns detailed song information with access control
func (uc *MusicUseCase) GetSongDetails(songID string, userType domain.UserType) (*domain.Song, error) {
	song, err := uc.repo.FindByID(songID)
	if err != nil {
		return nil, err
	}

	// Access control
	if userType == domain.FreeUser && song.AccessLevel != "free" {
		return nil, domain.ErrUnauthorized
	}

	return song, nil
}

// GetSongsByMood retrieves mood-filtered songs with access control
func (uc *MusicUseCase) GetSongsByMood(mood string, userType domain.UserType) ([]domain.Song, error) {
	songs, err := uc.repo.FindByMood(mood)
	if err != nil {
		return nil, err
	}

	if userType == domain.FreeUser {
		var freeSongs []domain.Song
		for _, song := range songs {
			if song.AccessLevel == "free" {
				freeSongs = append(freeSongs, song)
			}
		}
		if len(freeSongs) == 0 {
			return nil, domain.ErrSongNotFound
		}
		return freeSongs, nil
	}

	return songs, nil
}
