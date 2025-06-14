package repository

import (
	"context"

	gen "github.com/tmdgusya/zen/internal/repository/generated"
	"github.com/tmdgusya/zen/internal/types"
)

type JobRepositoryInterface interface {
	CreateJob(ctx context.Context, req *types.CreateJobRequest) (*gen.Jobs, error)
}
