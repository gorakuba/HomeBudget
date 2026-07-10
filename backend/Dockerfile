# Build stage
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Copy go mod and sum files first to leverage Docker cache
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the server binary
RUN CGO_ENABLED=0 GOOS=linux go build -o /homebudget-server ./cmd/server/main.go

# Final production stage
FROM alpine:3.19

WORKDIR /app

# Add CA certificates for secure HTTPS connections to Supabase/cloud DBs
RUN apk --no-cache add ca-certificates tzdata

COPY --from=builder /homebudget-server /app/homebudget-server

# Expose port (default 50051 or as overridden by $PORT)
EXPOSE 50051

USER 1000:1000

ENTRYPOINT ["/app/homebudget-server"]
