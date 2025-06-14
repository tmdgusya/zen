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
