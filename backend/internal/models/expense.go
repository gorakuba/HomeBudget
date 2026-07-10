package models

import "time"

type Expense struct {
	ID       string
	Title    string
	Amount   float64
	Category string
	Date     time.Time
}
