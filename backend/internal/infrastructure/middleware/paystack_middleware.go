package middlewares

import (
	"bytes"
	"crypto/hmac"
	"crypto/sha512"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"yefe_app/v1/internal/handlers/dto"
	"yefe_app/v1/pkg/logger"
)

type PaystackWebHookMiddleware struct {
	webbhookUrl string
	secretKey   string
	client      *http.Client
}

func NewPaystackMiddleware(webhookUrl string, secretkey string) *PaystackWebHookMiddleware {
	return &PaystackWebHookMiddleware{webbhookUrl: webhookUrl, secretKey: secretkey, client: &http.Client{}}
}

func (m PaystackWebHookMiddleware) Handle(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Only handle POST requests
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		// Read the request body
		body, err := io.ReadAll(r.Body)
		if err != nil {
			logger.Log.WithError(err).Error("Failed to read request body")
			http.Error(w, "Failed to read request body", http.StatusBadRequest)
			return
		}
		defer r.Body.Close()

		// Verify signature
		signature := r.Header.Get("X-Paystack-Signature")
		if !m.verifySignature(body, signature) {
			logger.Log.Info("Invalid signature")
			http.Error(w, "Invalid signature", http.StatusUnauthorized)
			return
		}

		// Parse webhook data
		var webhookData dto.PaystackWebhookEvent
		if err := json.Unmarshal(body, &webhookData); err != nil {
			logger.Log.WithError(err).Error("Failed to parse webhook data")
			http.Error(w, "Invalid JSON payload", http.StatusBadRequest)
			return
		}

		// Log the received webhook
		logger.Log.Infof("Received webhook - Event: %s, Reference: %s",
			webhookData.Event, webhookData.Data.Reference)

		// Check if we should process locally
		if m.shouldProcessLocally(webhookData) {
			next.ServeHTTP(w, r)
		} else {
			// Propagate entire request to fallback server
			if err := m.forwardToFallback(r, body); err != nil {
				logger.Log.WithError(err).Error("Failed to propagate to fallback")
				http.Error(w, "Failed to process webhook", http.StatusInternalServerError)
				return
			}
		}
	})
}

func (w *PaystackWebHookMiddleware) verifySignature(payload []byte, signature string) bool {
	if w.secretKey == "" {
		log.Println("Warning: Paystack secret key not set")
		return false
	}

	mac := hmac.New(sha512.New, []byte(w.secretKey))
	mac.Write(payload)
	expectedSignature := hex.EncodeToString(mac.Sum(nil))

	return hmac.Equal([]byte(expectedSignature), []byte(signature))
}

func (w *PaystackWebHookMiddleware) shouldProcessLocally(webhookData dto.PaystackWebhookEvent) bool {
	if from, ok := webhookData.Data.Metadata["FROM"]; ok {
		fromStr, ok := from.(string)
		return ok && fromStr == "mobile_app"
	}
	return false
}

// forwardToFallback forwards the request to the fallback server
func (w *PaystackWebHookMiddleware) forwardToFallback(originalReq *http.Request, payload []byte) error {
	if w.webbhookUrl == "" {
		return fmt.Errorf("fallback URL not configured")
	}

	req, err := http.NewRequest(http.MethodPost, w.webbhookUrl, bytes.NewBuffer(payload))
	if err != nil {
		return fmt.Errorf("failed to create request: %v", err)
	}

	for key, values := range originalReq.Header {
		for _, value := range values {
			req.Header.Add(key, value)
		}
	}
	resp, err := w.client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to forward request: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		return fmt.Errorf("fallback server returned status: %d", resp.StatusCode)
	}

	logger.Log.Infof("Successfully forwarded webhook to fallback server, status: %d", resp.StatusCode)
	return nil
}
