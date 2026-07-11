package models

import "time"

type Budget struct {
	Month     string
	Amount    float64
	UpdatedAt time.Time
}
