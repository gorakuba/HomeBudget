package mocks

import (
	"context"
	"fmt"

	"github.com/homebudget/backend/internal/models"
	"github.com/homebudget/backend/internal/repository"
)

type MockExpenseRepository struct {
	Expenses     map[string]*models.Expense
	CreateErr    error
	GetAllErr    error
	DeleteErr    error
	DeleteResult bool
	Budgets      map[string]*models.Budget
	GetBudgetErr error
	SetBudgetErr error
}

func NewMockExpenseRepository() *MockExpenseRepository {
	return &MockExpenseRepository{
		Expenses: make(map[string]*models.Expense),
		Budgets:  make(map[string]*models.Budget),
	}
}

func (m *MockExpenseRepository) Create(ctx context.Context, expense *models.Expense) (string, error) {
	if m.CreateErr != nil {
		return "", m.CreateErr
	}
	id := fmt.Sprintf("mock-uuid-%d", len(m.Expenses)+1)
	expense.ID = id
	m.Expenses[id] = expense
	return id, nil
}

func (m *MockExpenseRepository) GetAll(ctx context.Context) ([]*models.Expense, error) {
	if m.GetAllErr != nil {
		return nil, m.GetAllErr
	}
	var list []*models.Expense
	for _, e := range m.Expenses {
		list = append(list, e)
	}
	return list, nil
}

func (m *MockExpenseRepository) Delete(ctx context.Context, id string) (bool, error) {
	if m.DeleteErr != nil {
		return false, m.DeleteErr
	}
	if _, exists := m.Expenses[id]; exists {
		delete(m.Expenses, id)
		return true, nil
	}
	return m.DeleteResult, nil
}

func (m *MockExpenseRepository) GetBudget(ctx context.Context, month string) (*models.Budget, error) {
	if m.GetBudgetErr != nil {
		return nil, m.GetBudgetErr
	}
	if b, exists := m.Budgets[month]; exists {
		return b, nil
	}
	return &models.Budget{Month: month, Amount: 0}, nil
}

func (m *MockExpenseRepository) SetBudget(ctx context.Context, budget *models.Budget) (bool, error) {
	if m.SetBudgetErr != nil {
		return false, m.SetBudgetErr
	}
	m.Budgets[budget.Month] = budget
	return true, nil
}

var _ repository.ExpenseRepository = (*MockExpenseRepository)(nil)
