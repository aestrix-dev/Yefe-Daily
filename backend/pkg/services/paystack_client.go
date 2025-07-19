package service

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha512"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
	"yefe_app/v1/internal/handlers/dto"
)

var baseURL = "https://api.paystack.co"

func NewpaystackClient(secretKey string) *paystackClient {
	return &paystackClient{
		secretKey: secretKey,
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

type paystackClient struct {
	secretKey string
	client    *http.Client
}

func (p *paystackClient) InitializeTransaction(ctx context.Context, req dto.PaystackInitializeRequest) (*dto.PaystackInitializeResponse, error) {
	jsonData, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, "POST", baseURL+"/transaction/initialize", bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	httpReq.Header.Set("Authorization", "Bearer "+p.secretKey)
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := p.client.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("failed to make request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var paystackResp dto.PaystackInitializeResponse
	if err := json.Unmarshal(body, &paystackResp); err != nil {
		return nil, fmt.Errorf("failed to unmarshal response: %w", err)
	}

	if !paystackResp.Status {
		return nil, fmt.Errorf("paystack error: %s", paystackResp.Message)
	}

	return &paystackResp, nil
}

func (p *paystackClient) VerifyTransaction(ctx context.Context, reference string) (*dto.PaystackVerifyResponse, error) {
	url := fmt.Sprintf("%s/transaction/verify/%s", baseURL, reference)

	httpReq, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	httpReq.Header.Set("Authorization", "Bearer "+p.secretKey)

	resp, err := p.client.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("failed to make request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var paystackResp dto.PaystackVerifyResponse
	if err := json.Unmarshal(body, &paystackResp); err != nil {
		return nil, fmt.Errorf("failed to unmarshal response: %w", err)
	}

	if !paystackResp.Status {
		return nil, fmt.Errorf("paystack error: %s", paystackResp.Message)
	}

	return &paystackResp, nil
}

func (p *paystackClient) ValidateWebhook(body []byte, signature string) bool {
	mac := hmac.New(sha512.New, []byte(p.secretKey))
	mac.Write(body)
	expectedSignature := hex.EncodeToString(mac.Sum(nil))
	return hmac.Equal([]byte(signature), []byte(expectedSignature))
}
