package service

import (
	"context"
	"time"

	"github.com/homebudget/backend/internal/models"
	pb "github.com/homebudget/backend/internal/proto/expense"
	"github.com/homebudget/backend/internal/repository"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type expenseServiceServer struct {
	pb.UnimplementedExpenseServiceServer
	repo repository.ExpenseRepository
}

func NewExpenseServiceServer(repo repository.ExpenseRepository) pb.ExpenseServiceServer {
	return &expenseServiceServer{repo: repo}
}

func (s *expenseServiceServer) CreateExpense(ctx context.Context, req *pb.CreateExpenseRequest) (*pb.CreateExpenseResponse, error) {
	if req.GetTitle() == "" || req.GetAmount() <= 0 {
		return nil, status.Error(codes.InvalidArgument, "title cannot be empty and amount must be positive")
	}

	expense := &models.Expense{
		Title:    req.GetTitle(),
		Amount:   req.GetAmount(),
		Category: req.GetCategory(),
		Date:     time.Unix(req.GetDate(), 0),
	}

	id, err := s.repo.Create(ctx, expense)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to create expense: %v", err)
	}

	return &pb.CreateExpenseResponse{Id: id}, nil
}

func (s *expenseServiceServer) GetExpenses(ctx context.Context, req *pb.GetExpensesRequest) (*pb.GetExpensesResponse, error) {
	expenses, err := s.repo.GetAll(ctx)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to fetch expenses: %v", err)
	}

	var pbExpenses []*pb.ExpenseMessage
	for _, e := range expenses {
		pbExpenses = append(pbExpenses, &pb.ExpenseMessage{
			Id:       e.ID,
			Title:    e.Title,
			Amount:   e.Amount,
			Category: e.Category,
			Date:     e.Date.Unix(),
		})
	}

	return &pb.GetExpensesResponse{Expenses: pbExpenses}, nil
}

func (s *expenseServiceServer) DeleteExpense(ctx context.Context, req *pb.DeleteExpenseRequest) (*pb.DeleteExpenseResponse, error) {
	if req.GetId() == "" {
		return nil, status.Error(codes.InvalidArgument, "id cannot be empty")
	}

	success, err := s.repo.Delete(ctx, req.GetId())
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to delete expense: %v", err)
	}
	if !success {
		return nil, status.Errorf(codes.NotFound, "expense with id %s not found", req.GetId())
	}

	return &pb.DeleteExpenseResponse{Success: success}, nil
}

func (s *expenseServiceServer) GetBudget(ctx context.Context, req *pb.GetBudgetRequest) (*pb.GetBudgetResponse, error) {
	if req.GetMonth() == "" {
		return nil, status.Error(codes.InvalidArgument, "month cannot be empty")
	}

	budget, err := s.repo.GetBudget(ctx, req.GetMonth())
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to get budget: %v", err)
	}

	return &pb.GetBudgetResponse{Amount: budget.Amount}, nil
}

func (s *expenseServiceServer) SetBudget(ctx context.Context, req *pb.SetBudgetRequest) (*pb.SetBudgetResponse, error) {
	if req.GetMonth() == "" {
		return nil, status.Error(codes.InvalidArgument, "month cannot be empty")
	}
	if req.GetAmount() < 0 {
		return nil, status.Error(codes.InvalidArgument, "budget amount cannot be negative")
	}

	budget := &models.Budget{
		Month:  req.GetMonth(),
		Amount: req.GetAmount(),
	}

	success, err := s.repo.SetBudget(ctx, budget)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to set budget: %v", err)
	}

	return &pb.SetBudgetResponse{Success: success}, nil
}
