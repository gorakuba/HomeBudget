# Stage 1: Build binary using Golang compiler
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Copy Go module manifests from backend directory
COPY backend/go.mod backend/go.sum ./
RUN go mod download

# Copy backend source code
COPY backend/ .

# Build statically linked binary
RUN CGO_ENABLED=0 GOOS=linux go build -o /homebudget-server ./cmd/server/main.go

# Stage 2: Runtime image
FROM alpine:3.19

WORKDIR /app

# Install CA certificates to allow secure HTTPS/SSL database connections (e.g. Supabase)
RUN apk --no-cache add ca-certificates tzdata

COPY --from=builder /homebudget-server /app/homebudget-server

# Koyeb uses the PORT env variable and maps it. We expose port 8000 as default fallback.
EXPOSE 8000

# Run as non-root user for security
USER 1000:1000

ENTRYPOINT ["/app/homebudget-server"]
