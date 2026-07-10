package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	pb "github.com/homebudget/backend/internal/proto/expense"
	"github.com/homebudget/backend/internal/repository"
	"github.com/homebudget/backend/internal/service"
	"github.com/jackc/pgx/v5/pgxpool"
	"google.golang.org/grpc"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "50051"
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		// Default Supabase / Postgres connection string (override via env in production)
		dbURL = "postgres://postgres:password@localhost:5432/homebudget?sslmode=disable"
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	log.Printf("Connecting to database...")
	pool, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v\n", err)
	}
	defer pool.Close()

	if err := pool.Ping(ctx); err != nil {
		log.Printf("Warning: Failed to ping database (%v). Server starting in disconnected/offline mode.", err)
	} else {
		log.Println("Connected to PostgreSQL database successfully.")
	}

	repo := repository.NewPostgresExpenseRepository(pool)
	srv := service.NewExpenseServiceServer(repo)

	lis, err := net.Listen("tcp", fmt.Sprintf(":%s", port))
	if err != nil {
		log.Fatalf("Failed to listen on port %s: %v", port, err)
	}

	grpcServer := grpc.NewServer()
	pb.RegisterExpenseServiceServer(grpcServer, srv)

	// HTTP JSON Mux for iOS GRPCExpenseClient compatibility & health checks
	mux := http.NewServeMux()
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	mux.HandleFunc("/expense.ExpenseService/CreateExpense", func(w http.ResponseWriter, r *http.Request) {
		var req pb.CreateExpenseRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		resp, err := srv.CreateExpense(r.Context(), &req)
		if err != nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(resp)
	})

	mux.HandleFunc("/expense.ExpenseService/GetExpenses", func(w http.ResponseWriter, r *http.Request) {
		var req pb.GetExpensesRequest
		resp, err := srv.GetExpenses(r.Context(), &req)
		if err != nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(resp)
	})

	mux.HandleFunc("/expense.ExpenseService/DeleteExpense", func(w http.ResponseWriter, r *http.Request) {
		var req pb.DeleteExpenseRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		resp, err := srv.DeleteExpense(r.Context(), &req)
		if err != nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(resp)
	})

	// Dual handler: gRPC if application/grpc (and not json), otherwise HTTP JSON mux
	dualHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.ProtoMajor == 2 && strings.HasPrefix(r.Header.Get("Content-Type"), "application/grpc") && !strings.Contains(r.Header.Get("Content-Type"), "json") {
			grpcServer.ServeHTTP(w, r)
			return
		}
		mux.ServeHTTP(w, r)
	})

	httpServer := &http.Server{
		Handler: dualHandler,
	}

	// Graceful shutdown setup
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	go func() {
		log.Printf("Server listening at %v (supporting both gRPC and HTTP/JSON)", lis.Addr())
		if err := httpServer.Serve(lis); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to serve: %v", err)
		}
	}()

	<-sigChan
	log.Println("Shutting down server gracefully...")
	grpcServer.GracefulStop()
	httpServer.Shutdown(ctx)
	log.Println("Server stopped.")
}
