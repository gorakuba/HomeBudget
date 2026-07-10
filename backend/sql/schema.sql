-- Database Schema for HomeBudget (PostgreSQL / Supabase)

CREATE TABLE IF NOT EXISTS expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    category VARCHAR(100) NOT NULL,
    date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast sorting by date when fetching recent expenses
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses (date DESC);

-- Index for category-based summaries
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses (category);
