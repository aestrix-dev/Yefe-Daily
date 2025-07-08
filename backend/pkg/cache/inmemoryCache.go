package cache

import (
	"container/list"
	"context"
	"errors"
	"sync"
	"time"
)

// Common errors
var (
	ErrCacheContextCanceled = errors.New("cache operation canceled by context")
	ErrCacheContextTimeout  = errors.New("cache operation timed out")
)

// CacheItem represents an item in the cache
type CacheItem struct {
	Key         string
	Value       any
	CreatedAt   time.Time
	ExpiresAt   *time.Time
	AccessCount int64
}

// IsExpired checks if the item has expired
func (item *CacheItem) IsExpired() bool {
	return item.ExpiresAt != nil && time.Now().After(*item.ExpiresAt)
}

// CacheStats holds cache statistics
type CacheStats struct {
	Hits      int64
	Misses    int64
	Sets      int64
	Deletes   int64
	Evictions int64
	Size      int64
}

// CacheOptions configures the cache
type CacheOptions struct {
	MaxSize         int
	DefaultTTL      time.Duration
	CleanupInterval time.Duration
	EnableStats     bool
}

// Cache is a thread-safe in-memory cache with TTL and LRU eviction
type Cache struct {
	maxSize         int
	defaultTTL      time.Duration
	cleanupInterval time.Duration
	enableStats     bool

	// Core storage
	items map[string]*CacheItem

	// LRU tracking
	lruList *list.List
	lruMap  map[string]*list.Element

	// Statistics
	stats CacheStats

	// Synchronization
	mu sync.RWMutex

	// Cleanup
	stopCleanup chan struct{}
	cleanupDone chan struct{}
}

// NewCache creates a new cache with the given options
func NewCache(opts CacheOptions) *Cache {
	if opts.MaxSize == 0 {
		opts.MaxSize = 1000
	}
	if opts.DefaultTTL == 0 {
		opts.DefaultTTL = time.Hour
	}
	if opts.CleanupInterval == 0 {
		opts.CleanupInterval = 5 * time.Minute
	}

	cache := &Cache{
		maxSize:         opts.MaxSize,
		defaultTTL:      opts.DefaultTTL,
		cleanupInterval: opts.CleanupInterval,
		enableStats:     opts.EnableStats,
		items:           make(map[string]*CacheItem),
		lruList:         list.New(),
		lruMap:          make(map[string]*list.Element),
		stopCleanup:     make(chan struct{}),
		cleanupDone:     make(chan struct{}),
	}

	// Start cleanup goroutine
	if opts.CleanupInterval > 0 {
		go cache.cleanupRoutine()
	}

	return cache
}

// Get retrieves a value from the cache
func (c *Cache) Get(key string) (any, bool) {
	return c.GetWithContext(context.Background(), key)
}

// GetWithContext retrieves a value from the cache with context support
func (c *Cache) GetWithContext(ctx context.Context, key string) (any, bool) {
	// Check context first
	select {
	case <-ctx.Done():
		return nil, false
	default:
	}

	c.mu.Lock()
	defer c.mu.Unlock()

	item, exists := c.items[key]
	if !exists {
		if c.enableStats {
			c.stats.Misses++
		}
		return nil, false
	}

	// Check if expired
	if item.IsExpired() {
		c.deleteUnsafe(key)
		if c.enableStats {
			c.stats.Misses++
		}
		return nil, false
	}

	// Update LRU
	c.moveToFront(key)
	item.AccessCount++

	if c.enableStats {
		c.stats.Hits++
	}

	return item.Value, true
}

// Set stores a value in the cache with default TTL
func (c *Cache) Set(key string, value any) {
	c.SetWithContext(context.Background(), key, value)
}

// SetWithContext stores a value in the cache with context support
func (c *Cache) SetWithContext(ctx context.Context, key string, value any) {
	c.SetWithTTLAndContext(ctx, key, value, c.defaultTTL)
}

// SetWithTTL stores a value in the cache with specified TTL
func (c *Cache) SetWithTTL(key string, value any, ttl time.Duration) {
	c.SetWithTTLAndContext(context.Background(), key, value, ttl)
}

// SetWithTTLAndContext stores a value in the cache with specified TTL and context support
func (c *Cache) SetWithTTLAndContext(ctx context.Context, key string, value any, ttl time.Duration) {
	// Check context first
	select {
	case <-ctx.Done():
		return
	default:
	}

	c.mu.Lock()
	defer c.mu.Unlock()

	// Check if we need to evict
	if _, exists := c.items[key]; !exists && len(c.items) >= c.maxSize {
		c.evictLRUUnsafe()
	}

	// Create expiration time
	var expiresAt *time.Time
	if ttl > 0 {
		expTime := time.Now().Add(ttl)
		expiresAt = &expTime
	}

	// Create or update item
	item := &CacheItem{
		Key:         key,
		Value:       value,
		CreatedAt:   time.Now(),
		ExpiresAt:   expiresAt,
		AccessCount: 1,
	}

	c.items[key] = item
	c.addToLRU(key)

	if c.enableStats {
		c.stats.Sets++
		c.stats.Size = int64(len(c.items))
	}
}

// Delete removes a key from the cache
func (c *Cache) Delete(key string) bool {
	return c.DeleteWithContext(context.Background(), key)
}

// DeleteWithContext removes a key from the cache with context support
func (c *Cache) DeleteWithContext(ctx context.Context, key string) bool {
	// Check context first
	select {
	case <-ctx.Done():
		return false
	default:
	}

	c.mu.Lock()
	defer c.mu.Unlock()

	return c.deleteUnsafe(key)
}

// deleteUnsafe removes a key without locking (internal use)
func (c *Cache) deleteUnsafe(key string) bool {
	if _, exists := c.items[key]; !exists {
		return false
	}

	delete(c.items, key)
	c.removeFromLRU(key)

	if c.enableStats {
		c.stats.Deletes++
		c.stats.Size = int64(len(c.items))
	}

	return true
}

// Clear removes all items from the cache
func (c *Cache) Clear() {
	c.mu.Lock()
	defer c.mu.Unlock()

	c.items = make(map[string]*CacheItem)
	c.lruList.Init()
	c.lruMap = make(map[string]*list.Element)

	if c.enableStats {
		c.stats.Size = 0
	}
}

// Size returns the current number of items in the cache
func (c *Cache) Size() int {
	c.mu.RLock()
	defer c.mu.RUnlock()

	return len(c.items)
}

// Stats returns cache statistics
func (c *Cache) Stats() CacheStats {
	c.mu.RLock()
	defer c.mu.RUnlock()

	return c.stats
}

// Keys returns all cache keys
func (c *Cache) Keys() []string {
	c.mu.RLock()
	defer c.mu.RUnlock()

	keys := make([]string, 0, len(c.items))
	for key := range c.items {
		keys = append(keys, key)
	}
	return keys
}

// Has checks if a key exists in the cache
func (c *Cache) Has(key string) bool {
	return c.HasWithContext(context.Background(), key)
}

// HasWithContext checks if a key exists in the cache with context support
func (c *Cache) HasWithContext(ctx context.Context, key string) bool {
	// Check context first
	select {
	case <-ctx.Done():
		return false
	default:
	}

	c.mu.RLock()
	defer c.mu.RUnlock()

	item, exists := c.items[key]
	if !exists {
		return false
	}

	return !item.IsExpired()
}

// GetOrSet retrieves a value from cache or computes it if not found
func (c *Cache) GetOrSet(key string, computeFn func() any) any {
	return c.GetOrSetWithContext(context.Background(), key, computeFn)
}

// GetOrSetWithContext retrieves a value from cache or computes it if not found with context support
func (c *Cache) GetOrSetWithContext(ctx context.Context, key string, computeFn func() any) any {
	// Try to get from cache first
	if value, found := c.GetWithContext(ctx, key); found {
		return value
	}

	// Check context before computing
	select {
	case <-ctx.Done():
		return nil
	default:
	}

	// Compute value
	value := computeFn()

	// Set in cache
	c.SetWithContext(ctx, key, value)

	return value
}

// GetOrSetWithTTL retrieves a value from cache or computes it if not found with custom TTL
func (c *Cache) GetOrSetWithTTL(key string, computeFn func() any, ttl time.Duration) any {
	return c.GetOrSetWithTTLAndContext(context.Background(), key, computeFn, ttl)
}

// GetOrSetWithTTLAndContext retrieves a value from cache or computes it if not found with custom TTL and context
func (c *Cache) GetOrSetWithTTLAndContext(ctx context.Context, key string, computeFn func() any, ttl time.Duration) any {
	// Try to get from cache first
	if value, found := c.GetWithContext(ctx, key); found {
		return value
	}

	// Check context before computing
	select {
	case <-ctx.Done():
		return nil
	default:
	}

	// Compute value
	value := computeFn()

	// Set in cache with TTL
	c.SetWithTTLAndContext(ctx, key, value, ttl)

	return value
}

// GetMultiple retrieves multiple values from cache
func (c *Cache) GetMultiple(keys []string) map[string]any {
	return c.GetMultipleWithContext(context.Background(), keys)
}

// GetMultipleWithContext retrieves multiple values from cache with context support
func (c *Cache) GetMultipleWithContext(ctx context.Context, keys []string) map[string]any {
	result := make(map[string]any)

	for _, key := range keys {
		select {
		case <-ctx.Done():
			return result
		default:
		}

		if value, found := c.GetWithContext(ctx, key); found {
			result[key] = value
		}
	}

	return result
}

// SetMultiple stores multiple key-value pairs in cache
func (c *Cache) SetMultiple(items map[string]any) {
	c.SetMultipleWithContext(context.Background(), items)
}

// SetMultipleWithContext stores multiple key-value pairs in cache with context support
func (c *Cache) SetMultipleWithContext(ctx context.Context, items map[string]any) {
	for key, value := range items {
		select {
		case <-ctx.Done():
			return
		default:
		}

		c.SetWithContext(ctx, key, value)
	}
}

// DeleteMultiple removes multiple keys from cache
func (c *Cache) DeleteMultiple(keys []string) int {
	return c.DeleteMultipleWithContext(context.Background(), keys)
}

// DeleteMultipleWithContext removes multiple keys from cache with context support
func (c *Cache) DeleteMultipleWithContext(ctx context.Context, keys []string) int {
	deleted := 0

	for _, key := range keys {
		select {
		case <-ctx.Done():
			return deleted
		default:
		}

		if c.DeleteWithContext(ctx, key) {
			deleted++
		}
	}

	return deleted
}

// LRU management methods

func (c *Cache) addToLRU(key string) {
	if elem, exists := c.lruMap[key]; exists {
		c.lruList.MoveToFront(elem)
	} else {
		elem := c.lruList.PushFront(key)
		c.lruMap[key] = elem
	}
}

func (c *Cache) removeFromLRU(key string) {
	if elem, exists := c.lruMap[key]; exists {
		c.lruList.Remove(elem)
		delete(c.lruMap, key)
	}
}

func (c *Cache) moveToFront(key string) {
	if elem, exists := c.lruMap[key]; exists {
		c.lruList.MoveToFront(elem)
	}
}

func (c *Cache) evictLRUUnsafe() {
	if c.lruList.Len() == 0 {
		return
	}

	// Get least recently used item
	elem := c.lruList.Back()
	if elem != nil {
		key := elem.Value.(string)
		c.deleteUnsafe(key)

		if c.enableStats {
			c.stats.Evictions++
		}
	}
}

// Cleanup methods

func (c *Cache) cleanupRoutine() {
	ticker := time.NewTicker(c.cleanupInterval)
	defer ticker.Stop()
	defer close(c.cleanupDone)

	for {
		select {
		case <-ticker.C:
			c.cleanup()
		case <-c.stopCleanup:
			return
		}
	}
}

func (c *Cache) cleanup() {
	c.mu.Lock()
	defer c.mu.Unlock()

	now := time.Now()
	keysToDelete := make([]string, 0)

	// Find expired items
	for key, item := range c.items {
		if item.ExpiresAt != nil && now.After(*item.ExpiresAt) {
			keysToDelete = append(keysToDelete, key)
		}
	}

	// Delete expired items
	for _, key := range keysToDelete {
		c.deleteUnsafe(key)
	}
}

// Utility methods

// HitRate returns the cache hit rate as a percentage
func (c *Cache) HitRate() float64 {
	c.mu.RLock()
	defer c.mu.RUnlock()

	if c.stats.Hits+c.stats.Misses == 0 {
		return 0
	}

	return float64(c.stats.Hits) / float64(c.stats.Hits+c.stats.Misses) * 100
}

// ResetStats resets all cache statistics
func (c *Cache) ResetStats() {
	c.mu.Lock()
	defer c.mu.Unlock()

	c.stats = CacheStats{
		Size: int64(len(c.items)),
	}
}

// Example usage:
/*
func main() {
	// Create cache with custom options
	cache := NewCache(CacheOptions{
		MaxSize:         500,
		DefaultTTL:      30 * time.Minute,
		CleanupInterval: 10 * time.Minute,
		EnableStats:     true,
	})
	defer cache.Close()

	// Create a context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Set values with context
	cache.SetWithContext(ctx, "user:123", map[string]any{
		"name": "John Doe",
		"age":  30,
	})

	// Set with custom TTL and context
	cache.SetWithTTLAndContext(ctx, "temp:data", "temporary", 5*time.Minute)

	// Get values with context
	if value, found := cache.GetWithContext(ctx, "user:123"); found {
		fmt.Printf("Found: %+v\n", value)
	}

	// Use GetOrSet pattern with context
	result := cache.GetOrSetWithContext(ctx, "computed:data", func() any {
		// Expensive computation here
		return "computed result"
	})

	// Batch operations with context
	items := map[string]any{
		"key1": "value1",
		"key2": "value2",
		"key3": "value3",
	}
	cache.SetMultipleWithContext(ctx, items)

	results := cache.GetMultipleWithContext(ctx, []string{"key1", "key2", "key3"})
	fmt.Printf("Batch results: %+v\n", results)

	// Check stats
	stats := cache.Stats()
	fmt.Printf("Cache stats: %+v\n", stats)
	fmt.Printf("Hit rate: %.2f%%\n", cache.HitRate())

	// Close with context
	if err := cache.CloseWithContext(ctx); err != nil {
		fmt.Printf("Error closing cache: %v\n", err)
	}
}

// Example HTTP middleware usage:
func CacheMiddleware(cache *Cache) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Use request context
			ctx := r.Context()

			// Try to get cached response
			cacheKey := r.URL.Path + "?" + r.URL.RawQuery
			if cachedData, found := cache.GetWithContext(ctx, cacheKey); found {
				w.Header().Set("Content-Type", "application/json")
				w.Header().Set("X-Cache", "HIT")
				json.NewEncoder(w).Encode(cachedData)
				return
			}

			// Continue to next handler
			next.ServeHTTP(w, r)
		})
	}
}
*/
