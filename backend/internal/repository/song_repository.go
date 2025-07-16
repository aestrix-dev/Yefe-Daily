package repository

import (
	"encoding/json"
	"os"
	"strings"
	"yefe_app/v1/internal/domain"
)

// JSONMusicRepository implements the SongRepository interface
type JSONMusicRepository struct {
	filePath string
	cache    []domain.Song
}

// NewJSONMusicRepository creates a new JSON-backed repository
func NewJSONMusicRepository(filePath string) (*JSONMusicRepository, error) {
	repo := &JSONMusicRepository{filePath: filePath}
	if err := repo.loadSongs(); err != nil {
		return nil, err
	}
	return repo, nil
}

func (r *JSONMusicRepository) loadSongs() error {
	file, err := os.ReadFile(r.filePath)
	if err != nil {
		return domain.ErrResourceNotFound
	}

	var catalog domain.MusicCatalog
	if err := json.Unmarshal(file, &catalog); err != nil {
		return domain.ErrInvalidMusicFormat
	}

	r.cache = catalog.Pieces
	return nil
}

// FindAll returns all songs in the catalog
func (r *JSONMusicRepository) FindAll() ([]domain.Song, error) {
	if len(r.cache) == 0 {
		return nil, domain.ErrMusicMetadataMissing
	}
	return r.cache, nil
}

// FindByID locates a specific song by its ID
func (r *JSONMusicRepository) FindByID(id string) (*domain.Song, error) {
	for _, song := range r.cache {
		if song.ID == id {
			return &song, nil
		}
	}
	return nil, domain.ErrSongNotFound
}

// FindByAccessLevel returns songs filtered by access level
func (r *JSONMusicRepository) FindByAccessLevel(level string) ([]domain.Song, error) {
	if level != "free" && level != "pro" {
		return nil, domain.ErrInvalidAccessLevel
	}

	var result []domain.Song
	for _, song := range r.cache {
		if song.AccessLevel == level {
			result = append(result, song)
		}
	}

	if len(result) == 0 {
		return nil, domain.ErrSongNotFound
	}
	return result, nil
}

// FindByMood returns songs matching a specific mood/feel
func (r *JSONMusicRepository) FindByMood(mood string) ([]domain.Song, error) {
	var result []domain.Song
	for _, song := range r.cache {
		if strings.Contains(strings.ToLower(song.Feel), strings.ToLower(mood)) {
			result = append(result, song)
		}
	}

	if len(result) == 0 {
		return nil, domain.ErrSongNotFound
	}
	return result, nil
}
