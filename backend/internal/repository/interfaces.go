package repository

import (
	"context"

	"github.com/homebudget/backend/internal/models"
)

type ExpenseRepository interface {
	Create(ctx context.Context, expense *models.Expense) (string, error)
	GetAll(ctx context.Context) ([]*models.Expense, error)
	Delete(ctx context.Context, id string) (bool, error)
	GetBudget(ctx context.Context, month string) (*models.Budget, error)
	SetBudget(ctx context.Context, budget *models.Budget) (bool, error)
}
