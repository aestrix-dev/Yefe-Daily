package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

	"yefe_app/v1/internal/domain"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/utils"

	"github.com/go-chi/chi/v5"
)

type journalHandler struct {
	journalUseCase domain.JournalUseCase
}

// NewJournalHandler creates a new journal handler
func NewJournalHandler(journalUseCase domain.JournalUseCase) *journalHandler {
	return &journalHandler{
		journalUseCase: journalUseCase,
	}
}

func (j journalHandler) Handle() *chi.Mux {
	router := chi.NewRouter()
	router.Post("/entries", j.CreateEntry)
	router.Get("/entries", j.GetEntries)
	router.Get("/entries/{id}", j.GetEntry)
	router.Put("/entries/{id}", j.UpdateEntry)
	router.Delete("/entries/{id}", j.DeleteEntry)
	router.Get("/entries/today/{type}", j.GetTodayEntry)
	router.Get("/stats", j.GetStats)

	return router
}

// CreateEntry handles POST /journal/entries
func (h *journalHandler) CreateEntry(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())
	if userID == "" {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	var req dto.CreateJournalEntryRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", nil)
		return
	}

	entry, err := h.journalUseCase.CreateEntry(r.Context(), userID, req)
	if err != nil {
		utils.HandleDomainError(w, err)
		return
	}
	utils.SuccessResponse(w, http.StatusCreated, "new entry created", entry)
}

// GetEntry handles GET /journal/entries/{id}
func (h *journalHandler) GetEntry(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())
	if userID == "" {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	entryID := chi.URLParam(r, "id")
	if entryID == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Entry ID is required", nil)
		return
	}

	entry, err := h.journalUseCase.GetEntry(r.Context(), userID, entryID)
	if err != nil {
		utils.HandleDomainError(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(entry)
}

// GetEntries handles GET /journal/entries
func (h *journalHandler) GetEntries(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())
	if userID == "" {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	// Parse query parameters
	limit := 20 // default
	if l := r.URL.Query().Get("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 {
			limit = parsed
		}
	}

	offset := 0
	if o := r.URL.Query().Get("offset"); o != "" {
		if parsed, err := strconv.Atoi(o); err == nil && parsed >= 0 {
			offset = parsed
		}
	}

	// Build filter from query parameters
	filter := dto.JournalEntryFilter{
		Limit:  limit,
		Offset: offset,
	}

	if entryType := r.URL.Query().Get("type"); entryType != "" {
		filter.Type = entryType
	}

	if tags := r.URL.Query().Get("tags"); tags != "" {
		tagList := strings.Split(tags, ",")
		for i, tag := range tagList {
			tagList[i] = strings.TrimSpace(tag)
		}
		filter.Tags = tagList
	}

	if search := r.URL.Query().Get("search"); search != "" {
		filter.Search = search
	}

	if startDate := r.URL.Query().Get("start_date"); startDate != "" {
		if parsed, err := time.Parse("2006-01-02", startDate); err == nil {
			filter.StartDate = &parsed
		}
	}

	if endDate := r.URL.Query().Get("end_date"); endDate != "" {
		if parsed, err := time.Parse("2006-01-02", endDate); err == nil {
			filter.EndDate = &parsed
		}
	}

	entries, err := h.journalUseCase.GetEntries(r.Context(), userID, filter)
	if err != nil {
		utils.HandleDomainError(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(entries)
}

// UpdateEntry handles PUT /journal/entries/{id}
func (h *journalHandler) UpdateEntry(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())
	if userID == "" {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	entryID := chi.URLParam(r, "id")
	if entryID == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Entry ID is required", nil)
		return
	}

	var req dto.UpdateJournalEntryRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body", nil)
		return
	}

	entry, err := h.journalUseCase.UpdateEntry(r.Context(), userID, entryID, req)
	if err != nil {
		utils.HandleDomainError(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(entry)
}

// DeleteEntry handles DELETE /journal/entries/{id}
func (h *journalHandler) DeleteEntry(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())
	if userID == "" {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	entryID := chi.URLParam(r, "id")
	if entryID == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Entry ID is required", nil)
		return
	}

	if err := h.journalUseCase.DeleteEntry(r.Context(), userID, entryID); err != nil {
		utils.HandleDomainError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// GetTodayEntry handles GET /journal/entries/today/{type}
func (h *journalHandler) GetTodayEntry(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())
	if userID == "" {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	entryType := chi.URLParam(r, "type")
	if entryType == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Entry type is required", nil)
		return
	}

	entry, err := h.journalUseCase.GetTodayEntry(r.Context(), userID, entryType)
	if err != nil {
		utils.HandleDomainError(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(entry)
}

// GetStats handles GET /journal/stats
func (h *journalHandler) GetStats(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())
	if userID == "" {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	stats, err := h.journalUseCase.GetStats(r.Context(), userID)
	if err != nil {
		utils.HandleDomainError(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(stats)
}

// SearchEntries handles GET /journal/search
func (h *journalHandler) SearchEntries(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())
	if userID == "" {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Unauthorized", nil)
		return
	}

	query := r.URL.Query().Get("q")
	if query == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Search query is required", nil)
		return
	}

	// Parse pagination parameters
	limit := 20 // default
	if l := r.URL.Query().Get("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 {
			limit = parsed
		}
	}

	offset := 0
	if o := r.URL.Query().Get("offset"); o != "" {
		if parsed, err := strconv.Atoi(o); err == nil && parsed >= 0 {
			offset = parsed
		}
	}

	entries, err := h.journalUseCase.SearchEntries(r.Context(), userID, query, limit, offset)
	if err != nil {
		utils.HandleDomainError(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(entries)
}
