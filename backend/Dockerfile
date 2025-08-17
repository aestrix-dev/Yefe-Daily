# Build stage
FROM golang:1.24-alpine AS builder

# Set working directory
WORKDIR /yefa_daily

# Copy go mod files first for better caching
COPY go.mod go.sum ./

# Download dependencies
RUN go mod tidy 

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./main.go

# Final stage
FROM alpine:latest

# Install runtime dependencies
RUN apk --no-cache add ca-certificates tzdata

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Set working directory
WORKDIR /yefa_daily

# Copy binary from builder stage
COPY --from=builder /yefa_daily/main .

COPY --from=builder /yefa_daily/config/* ./config
COPY --from=builder /yefa_daily/extras/* ./extras

# Switch to non-root user
USER appuser

# Expose port (adjust as needed)
EXPOSE 8080

# Run the application
CMD ["./main"]
