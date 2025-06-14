package repository

import (
	"context"
	"database/sql"

	gen "github.com/tmdgusya/zen/internal/repository/generated"
	"github.com/tmdgusya/zen/internal/types"
)

type JobRepository struct {
	queries *gen.Queries
}

func NewJobRepository(queries *gen.Queries) *JobRepository {
	return &JobRepository{queries: queries}
}

func (r *JobRepository) CreateJob(ctx context.Context, req *types.CreateJobRequest) (*gen.Jobs, error) {
	job, err := r.queries.CreateJob(ctx, gen.CreateJobParams{
		Name:           req.Name,
		Description:    sql.NullString{String: req.Description, Valid: true},
		PythonFilePath: req.PythonFilePath,
		CronExpression: req.CronExpression,
		IsActive:       req.IsActive,
		TimeoutSeconds: sql.NullInt64{Int64: req.TimeoutSeconds, Valid: true},
		MaxRetries:     sql.NullInt64{Int64: req.MaxRetries, Valid: true},
	})

	if err != nil {
		return nil, err
	}

	return &job, nil
}
