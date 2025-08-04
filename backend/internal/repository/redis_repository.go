package repository

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"time"
	"yefe_app/v1/internal/domain"
	"yefe_app/v1/pkg/logger"
	"yefe_app/v1/pkg/utils"

	"github.com/redis/go-redis/v9"
)

// RedisSessionRepository implements SessionRepository using Redis
type RedisSessionRepository struct {
	client *redis.Client
}

func NewRedisSessionRepository(config utils.DBSettings) (*RedisSessionRepository, error) {
	redisConnAddr := fmt.Sprintf("%s:%s", config.Host, config.Port)
	options := &redis.Options{
		Username:  config.UserName,
		Password:  config.Password,
		Addr:      redisConnAddr,
		TLSConfig: &tls.Config{},
	}

	client := redis.NewClient(options)
	err := client.Ping(context.Background()).Err()
	if err != nil {
		logger.Log.WithError(err).Fatal("redis could not connect")
		return nil, err
	}
	return newRedisSessionRepository(client), nil
}

// NewRedisSessionRepository creates a new Redis session repository
func newRedisSessionRepository(client *redis.Client) *RedisSessionRepository {
	return &RedisSessionRepository{
		client: client,
	}
}

// Redis key patterns
const (
	sessionKeyPrefix   = "session:"
	tokenKeyPrefix     = "token:"
	userSessionsPrefix = "user_sessions:"
	expiredSessionsKey = "expired_sessions"
)

// Create stores a new session in Redis
func (r *RedisSessionRepository) Create(ctx context.Context, session *domain.Session) error {
	sessionKey := sessionKeyPrefix + session.ID

	// Serialize session
	sessionData, err := json.Marshal(session)
	if err != nil {
		return fmt.Errorf("failed to marshal session: %w", err)
	}

	// Calculate TTL
	//ttl := time.Until(session.ExpiresAt)
	//	if ttl <= 0 {
	//	return fmt.Errorf("session is already expired")
	//}

	// Use pipeline for atomic operations
	pipe := r.client.Pipeline()

	// Store session data
	pipe.Set(ctx, sessionKey, sessionData, 0) //, ttl)

	// Store token -> session ID mapping
	//	pipe.Set(ctx, tokenKey, session.ID, ttl)

	// Add to user's session set
	//pipe.SAdd(ctx, userSessionsKey, session.ID)
	//	pipe.Expire(ctx, userSessionsKey, ttl)

	// Add to expired sessions sorted set for cleanup
	pipe.ZAdd(ctx, expiredSessionsKey, redis.Z{
		Score:  float64(session.ExpiresAt.Unix()),
		Member: session.ID,
	})

	_, err = pipe.Exec(ctx)
	if err != nil {
		return fmt.Errorf("failed to create session: %w", err)
	}

	return nil
}

// GetByToken retrieves a session by its id
func (r *RedisSessionRepository) GetByID(ctx context.Context, sessionID string) (*domain.Session, error) {

	// Get session data
	sessionKey := sessionKeyPrefix + sessionID
	sessionData, err := r.client.Get(ctx, sessionKey).Result()
	if err != nil {
		if err == redis.Nil {
			return nil, fmt.Errorf("session not found")
		}
		return nil, fmt.Errorf("failed to get session: %w", err)
	}

	var session domain.Session
	if err := json.Unmarshal([]byte(sessionData), &session); err != nil {
		return nil, fmt.Errorf("failed to unmarshal session: %w", err)
	}

	return &session, nil
}

// GetByUserID retrieves all sessions for a user
func (r *RedisSessionRepository) GetByUserID(ctx context.Context, userID string) ([]*domain.Session, error) {
	userSessionsKey := userSessionsPrefix + userID

	// Get all session IDs for the user
	sessionIDs, err := r.client.SMembers(ctx, userSessionsKey).Result()
	if err != nil {
		return nil, fmt.Errorf("failed to get user sessions: %w", err)
	}

	if len(sessionIDs) == 0 {
		return []*domain.Session{}, nil
	}

	// Get all sessions in one pipeline
	pipe := r.client.Pipeline()
	cmds := make([]*redis.StringCmd, len(sessionIDs))

	for i, sessionID := range sessionIDs {
		sessionKey := sessionKeyPrefix + sessionID
		cmds[i] = pipe.Get(ctx, sessionKey)
	}

	_, err = pipe.Exec(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get sessions: %w", err)
	}

	sessions := make([]*domain.Session, 0, len(sessionIDs))
	for i, cmd := range cmds {
		sessionData, err := cmd.Result()
		if err != nil {
			if err == redis.Nil {
				// Session expired, remove from user set
				r.client.SRem(ctx, userSessionsKey, sessionIDs[i])
				continue
			}
			return nil, fmt.Errorf("failed to get session data: %w", err)
		}

		var session domain.Session
		if err := json.Unmarshal([]byte(sessionData), &session); err != nil {
			return nil, fmt.Errorf("failed to unmarshal session: %w", err)
		}

		sessions = append(sessions, &session)
	}

	return sessions, nil
}

// Update updates an existing session
func (r *RedisSessionRepository) Update(ctx context.Context, session *domain.Session) error {
	session.UpdatedAt = time.Now()

	sessionKey := sessionKeyPrefix + session.ID
	tokenKey := tokenKeyPrefix + session.Token
	userSessionsKey := userSessionsPrefix + session.UserID

	// Check if session exists
	exists, err := r.client.Exists(ctx, sessionKey).Result()
	if err != nil {
		return fmt.Errorf("failed to check session existence: %w", err)
	}
	if exists == 0 {
		return fmt.Errorf("session not found")
	}

	// Serialize session
	sessionData, err := json.Marshal(session)
	if err != nil {
		return fmt.Errorf("failed to marshal session: %w", err)
	}

	// Calculate TTL
	ttl := time.Until(session.ExpiresAt)
	if ttl <= 0 {
		return fmt.Errorf("session is already expired")
	}

	// Use pipeline for atomic operations
	pipe := r.client.Pipeline()

	// Update session data
	pipe.Set(ctx, sessionKey, sessionData, ttl)

	// Update token mapping
	pipe.Set(ctx, tokenKey, session.ID, ttl)

	// Update user sessions set
	pipe.SAdd(ctx, userSessionsKey, session.ID)
	pipe.Expire(ctx, userSessionsKey, ttl)

	// Update expired sessions sorted set
	pipe.ZAdd(ctx, expiredSessionsKey, redis.Z{
		Score:  float64(session.ExpiresAt.Unix()),
		Member: session.ID,
	})

	_, err = pipe.Exec(ctx)
	if err != nil {
		return fmt.Errorf("failed to update session: %w", err)
	}

	return nil
}

// Delete removes a session by ID
func (r *RedisSessionRepository) Delete(ctx context.Context, id string) error {
	sessionKey := sessionKeyPrefix + id

	// Get session to find token and user ID
	sessionData, err := r.client.Get(ctx, sessionKey).Result()
	if err != nil {
		if err == redis.Nil {
			return fmt.Errorf("session not found")
		}
		return nil // Session doesn't exist, consider it deleted
	}

	var session domain.Session
	if err := json.Unmarshal([]byte(sessionData), &session); err != nil {
		return fmt.Errorf("failed to unmarshal session: %w", err)
	}

	// Use pipeline for atomic operations
	pipe := r.client.Pipeline()

	// Delete session data
	pipe.Del(ctx, sessionKey)

	// Delete token mapping
	tokenKey := tokenKeyPrefix + session.Token
	pipe.Del(ctx, tokenKey)

	// Remove from user sessions set
	userSessionsKey := userSessionsPrefix + session.UserID
	pipe.SRem(ctx, userSessionsKey, id)

	// Remove from expired sessions sorted set
	pipe.ZRem(ctx, expiredSessionsKey, id)

	_, err = pipe.Exec(ctx)
	if err != nil {
		return fmt.Errorf("failed to delete session: %w", err)
	}

	return nil
}

// DeleteByUserID removes all sessions for a user
func (r *RedisSessionRepository) DeleteByUserID(ctx context.Context, userID string) error {
	userSessionsKey := userSessionsPrefix + userID

	// Get all session IDs for the user
	sessionIDs, err := r.client.SMembers(ctx, userSessionsKey).Result()
	if err != nil {
		return fmt.Errorf("failed to get user sessions: %w", err)
	}

	if len(sessionIDs) == 0 {
		return nil // No sessions to delete
	}

	// Get all sessions to find their tokens
	pipe := r.client.Pipeline()
	sessionCmds := make([]*redis.StringCmd, len(sessionIDs))

	for i, sessionID := range sessionIDs {
		sessionKey := sessionKeyPrefix + sessionID
		sessionCmds[i] = pipe.Get(ctx, sessionKey)
	}

	_, err = pipe.Exec(ctx)
	if err != nil {
		return fmt.Errorf("failed to get sessions for deletion: %w", err)
	}

	// Delete all sessions and their tokens
	deletePipe := r.client.Pipeline()

	for i, cmd := range sessionCmds {
		sessionData, err := cmd.Result()
		if err == redis.Nil {
			continue // Session already expired
		}
		if err != nil {
			return fmt.Errorf("failed to get session data: %w", err)
		}

		var session domain.Session
		if err := json.Unmarshal([]byte(sessionData), &session); err != nil {
			continue // Skip corrupted session
		}

		// Delete session
		sessionKey := sessionKeyPrefix + sessionIDs[i]
		deletePipe.Del(ctx, sessionKey)

		// Delete token mapping
		tokenKey := tokenKeyPrefix + session.Token
		deletePipe.Del(ctx, tokenKey)

		// Remove from expired sessions sorted set
		deletePipe.ZRem(ctx, expiredSessionsKey, sessionIDs[i])
	}

	// Delete user sessions set
	deletePipe.Del(ctx, userSessionsKey)

	_, err = deletePipe.Exec(ctx)
	if err != nil {
		return fmt.Errorf("failed to delete user sessions: %w", err)
	}

	return nil
}

// DeleteExpired removes all expired sessions
func (r *RedisSessionRepository) DeleteExpired(ctx context.Context) error {
	now := time.Now().Unix()

	// Get expired session IDs
	expiredIDs, err := r.client.ZRangeByScore(ctx, expiredSessionsKey, &redis.ZRangeBy{
		Min: "-inf",
		Max: fmt.Sprintf("%d", now),
	}).Result()
	if err != nil {
		return fmt.Errorf("failed to get expired sessions: %w", err)
	}

	if len(expiredIDs) == 0 {
		return nil // No expired sessions
	}

	// Get session data to find tokens and user IDs
	pipe := r.client.Pipeline()
	sessionCmds := make([]*redis.StringCmd, len(expiredIDs))

	for i, sessionID := range expiredIDs {
		sessionKey := sessionKeyPrefix + sessionID
		sessionCmds[i] = pipe.Get(ctx, sessionKey)
	}

	_, err = pipe.Exec(ctx)
	if err != nil {
		return fmt.Errorf("failed to get expired session data: %w", err)
	}

	// Delete expired sessions
	deletePipe := r.client.Pipeline()

	for i, cmd := range sessionCmds {
		sessionData, err := cmd.Result()
		if err == redis.Nil {
			// Session already deleted, just remove from sorted set
			deletePipe.ZRem(ctx, expiredSessionsKey, expiredIDs[i])
			continue
		}
		if err != nil {
			continue // Skip on error
		}

		var session domain.Session
		if err := json.Unmarshal([]byte(sessionData), &session); err != nil {
			continue // Skip corrupted session
		}

		// Delete session
		sessionKey := sessionKeyPrefix + expiredIDs[i]
		deletePipe.Del(ctx, sessionKey)

		// Delete token mapping
		tokenKey := tokenKeyPrefix + session.Token
		deletePipe.Del(ctx, tokenKey)

		// Remove from user sessions set
		userSessionsKey := userSessionsPrefix + session.UserID
		deletePipe.SRem(ctx, userSessionsKey, expiredIDs[i])
	}

	// Remove expired sessions from sorted set
	deletePipe.ZRemRangeByScore(ctx, expiredSessionsKey, "-inf", fmt.Sprintf("%d", now))

	_, err = deletePipe.Exec(ctx)
	if err != nil {
		return fmt.Errorf("failed to delete expired sessions: %w", err)
	}

	return nil
}
