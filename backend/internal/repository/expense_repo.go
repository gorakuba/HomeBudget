package repository

import (
	"context"
	"fmt"

	"github.com/homebudget/backend/internal/models"
	"github.com/jackc/pgx/v5/pgxpool"
)

type postgresExpenseRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresExpenseRepository(pool *pgxpool.Pool) ExpenseRepository {
	return &postgresExpenseRepository{pool: pool}
}

func (r *postgresExpenseRepository) Create(ctx context.Context, expense *models.Expense) (string, error) {
	query := `
		INSERT INTO expenses (title, amount, category, date)
		VALUES ($1, $2, $3, $4)
		RETURNING id
	`
	var id string
	err := r.pool.QueryRow(ctx, query, expense.Title, expense.Amount, expense.Category, expense.Date).Scan(&id)
	if err != nil {
		return "", fmt.Errorf("failed to create expense in database: %w", err)
	}
	return id, nil
}

func (r *postgresExpenseRepository) GetAll(ctx context.Context) ([]*models.Expense, error) {
	query := `
		SELECT id, title, amount, category, date
		FROM expenses
		ORDER BY date DESC
	`
	rows, err := r.pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to query expenses: %w", err)
	}
	defer rows.Close()

	var expenses []*models.Expense
	for rows.Next() {
		var e models.Expense
		if err := rows.Scan(&e.ID, &e.Title, &e.Amount, &e.Category, &e.Date); err != nil {
			return nil, fmt.Errorf("failed to scan expense row: %w", err)
		}
		expenses = append(expenses, &e)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("rows error: %w", err)
	}

	return expenses, nil
}

func (r *postgresExpenseRepository) Delete(ctx context.Context, id string) (bool, error) {
	query := `DELETE FROM expenses WHERE id = $1`
	cmdTag, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return false, fmt.Errorf("failed to delete expense: %w", err)
	}
	return cmdTag.RowsAffected() > 0, nil
}
