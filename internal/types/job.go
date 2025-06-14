package types

import (
	"time"

	gen "github.com/tmdgusya/zen/internal/repository/generated"
)

type CreateJobRequest struct {
	Name           string
	Description    string
	PythonFilePath string
	CronExpression string
	IsActive       bool
	TimeoutSeconds int64
	MaxRetries     int64
}

type CreateJobResponse struct {
	ID          int64     `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	CreatedAt   time.Time `json:"created_at"`
}

func (r CreateJobResponse) FromJob(job *gen.Jobs) *CreateJobResponse {
	return &CreateJobResponse{
		ID:          job.ID,
		Name:        job.Name,
		Description: job.Description.String,
		CreatedAt:   job.CreatedAt,
	}
}

type GetJobResponse struct {
	ID             int64     `json:"id"`
	Name           string    `json:"name"`
	Description    string    `json:"description"`
	PythonFilePath string    `json:"python_file_path"`
	CronExpression string    `json:"cron_expression"`
	IsActive       bool      `json:"is_active"`
	TimeoutSeconds int64     `json:"timeout_seconds"`
	MaxRetries     int64     `json:"max_retries"`
	CreatedAt      time.Time `json:"created_at"`
}

func (r GetJobResponse) FromJob(job *gen.Jobs) *GetJobResponse {
	return &GetJobResponse{
		ID:             job.ID,
		Name:           job.Name,
		Description:    job.Description.String,
		PythonFilePath: job.PythonFilePath,
		CronExpression: job.CronExpression,
		IsActive:       job.IsActive,
		TimeoutSeconds: job.TimeoutSeconds.Int64,
		MaxRetries:     job.MaxRetries.Int64,
		CreatedAt:      job.CreatedAt,
	}
}
