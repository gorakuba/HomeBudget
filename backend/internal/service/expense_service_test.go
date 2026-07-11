package service

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/homebudget/backend/internal/mocks"
	"github.com/homebudget/backend/internal/models"
	pb "github.com/homebudget/backend/internal/proto/expense"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func TestCreateExpense_Success(t *testing.T) {
	mockRepo := mocks.NewMockExpenseRepository()
	srv := NewExpenseServiceServer(mockRepo)

	req := &pb.CreateExpenseRequest{
		Title:    "Test Expense",
		Amount:   120.50,
		Category: "food",
		Date:     time.Now().Unix(),
	}

	resp, err := srv.CreateExpense(context.Background(), req)
	if err != nil {
		t.Fatalf("expected success, got error: %v", err)
	}
	if resp.GetId() == "" {
		t.Errorf("expected non-empty id, got empty")
	}
	if len(mockRepo.Expenses) != 1 {
		t.Errorf("expected 1 expense in repo, got %d", len(mockRepo.Expenses))
	}
}

func TestCreateExpense_RepoError(t *testing.T) {
	mockRepo := mocks.NewMockExpenseRepository()
	mockRepo.CreateErr = errors.New("database connection lost")
	srv := NewExpenseServiceServer(mockRepo)

	req := &pb.CreateExpenseRequest{
		Title:    "Test Expense",
		Amount:   120.50,
		Category: "food",
		Date:     time.Now().Unix(),
	}

	_, err := srv.CreateExpense(context.Background(), req)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}

	st, ok := status.FromError(err)
	if !ok {
		t.Fatalf("expected grpc status error, got %v", err)
	}
	if st.Code() != codes.Internal {
		t.Errorf("expected code Internal (%v), got %v", codes.Internal, st.Code())
	}
}

func TestGetExpenses_Success(t *testing.T) {
	mockRepo := mocks.NewMockExpenseRepository()
	srv := NewExpenseServiceServer(mockRepo)

	// Prepopulate
	_, _ = srv.CreateExpense(context.Background(), &pb.CreateExpenseRequest{
		Title:    "Item 1",
		Amount:   10,
		Category: "food",
		Date:     time.Now().Unix(),
	})

	resp, err := srv.GetExpenses(context.Background(), &pb.GetExpensesRequest{})
	if err != nil {
		t.Fatalf("expected success, got error: %v", err)
	}
	if len(resp.GetExpenses()) != 1 {
		t.Errorf("expected 1 expense, got %d", len(resp.GetExpenses()))
	}
}

func TestGetBudget_Success(t *testing.T) {
	mockRepo := mocks.NewMockExpenseRepository()
	srv := NewExpenseServiceServer(mockRepo)

	// Set value in mock
	mockRepo.Budgets["2026-07"] = &models.Budget{Month: "2026-07", Amount: 4500.0}

	resp, err := srv.GetBudget(context.Background(), &pb.GetBudgetRequest{Month: "2026-07"})
	if err != nil {
		t.Fatalf("expected success, got error: %v", err)
	}
	if resp.GetAmount() != 4500.0 {
		t.Errorf("expected budget amount 4500.0, got %f", resp.GetAmount())
	}
}

func TestSetBudget_Success(t *testing.T) {
	mockRepo := mocks.NewMockExpenseRepository()
	srv := NewExpenseServiceServer(mockRepo)

	resp, err := srv.SetBudget(context.Background(), &pb.SetBudgetRequest{Month: "2026-07", Amount: 6200.0})
	if err != nil {
		t.Fatalf("expected success, got error: %v", err)
	}
	if !resp.GetSuccess() {
		t.Errorf("expected success to be true")
	}

	budget := mockRepo.Budgets["2026-07"]
	if budget == nil {
		t.Fatalf("expected budget to be saved in mock repo, got nil")
	}
	if budget.Amount != 6200.0 {
		t.Errorf("expected budget amount in mock repo to be 6200.0, got %f", budget.Amount)
	}
}
