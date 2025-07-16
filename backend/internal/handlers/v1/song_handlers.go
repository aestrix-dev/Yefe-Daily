package handlers

import (
	"net/http"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/pkg/utils"

	"github.com/go-chi/chi/v5"
)

type musicHandler struct {
	songUC domain.SongUseCase
}

func NewMusicHandler(songUC domain.SongUseCase) *musicHandler {
	return &musicHandler{
		songUC: songUC,
	}
}

func (h *musicHandler) Handle() *chi.Mux {
	router := chi.NewRouter()
	router.Get("/", h.GetSongs)
	router.Get("/{id}", h.GetSongDetails)
	router.Get("/mood/{mood}", h.GetSongsByMood)

	return router
}

// GetSongs returns songs based on user's access level
func (h *musicHandler) GetSongs(w http.ResponseWriter, r *http.Request) {
	user := r.Context().Value("user").(*domain.User)

	var userType domain.UserType
	if user.IsYefePlusPlan() {
		userType = domain.ProUser
	} else {
		userType = domain.FreeUser
	}

	songs, err := h.songUC.GetSongs(userType)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to retrieve songs", nil)
		return
	}

	utils.SuccessResponse(w, http.StatusOK, "successfully got songs", map[string]interface{}{
		"data": songs,
		"meta": map[string]interface{}{
			"total":  len(songs),
			"access": userType,
		},
	})
}

// GetSongDetails returns detailed information about a specific song
func (h *musicHandler) GetSongDetails(w http.ResponseWriter, r *http.Request) {
	user := r.Context().Value("user").(*domain.User)
	songID := chi.URLParam(r, "id")

	var userType domain.UserType
	if user.IsYefePlusPlan() {
		userType = domain.ProUser
	} else {
		userType = domain.FreeUser
	}

	song, err := h.songUC.GetSongDetails(songID, userType)
	if err != nil {
		switch err {
		case domain.ErrSongNotFound:
			utils.ErrorResponse(w, http.StatusNotFound, "Song not found", nil)
		case domain.ErrUnauthorized:
			utils.ErrorResponse(w, http.StatusForbidden, "Upgrade to pro to access this song", nil)
		default:
			utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to retrieve song details", nil)
		}
		return
	}

	utils.SuccessResponse(w, http.StatusOK, "users", song)
}

// GetSongsByMood returns songs filtered by mood
func (h *musicHandler) GetSongsByMood(w http.ResponseWriter, r *http.Request) {
	user := r.Context().Value("user").(*domain.User)
	mood := chi.URLParam(r, "mood")

	var userType domain.UserType
	if user.IsYefePlusPlan() {
		userType = domain.ProUser
	} else {
		userType = domain.FreeUser
	}

	songs, err := h.songUC.GetSongsByMood(mood, userType)
	if err != nil {
		switch err {
		case domain.ErrSongNotFound:
			utils.ErrorResponse(w, http.StatusNotFound, "No songs found with this mood", nil)
		default:
			utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to retrieve songs", nil)
		}
		return
	}

	utils.SuccessResponse(w, http.StatusOK, "successfully got songs", map[string]interface{}{
		"data": songs,
		"meta": map[string]interface{}{
			"mood":   mood,
			"total":  len(songs),
			"access": userType,
		},
	})
}
