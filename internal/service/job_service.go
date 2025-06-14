package service

import (
	"context"

	"github.com/tmdgusya/zen/internal/repository"
	"github.com/tmdgusya/zen/internal/types"
)

type JobService struct {
	jobRepo repository.JobRepositoryInterface
}

func NewJobService(jobRepo repository.JobRepositoryInterface) *JobService {
	return &JobService{jobRepo: jobRepo}
}

func (s *JobService) CreateJob(ctx context.Context, req *types.CreateJobRequest) (*types.CreateJobResponse, error) {
	job, err := s.jobRepo.CreateJob(ctx, req)
	if err != nil {
		return nil, err
	}

	response := &types.CreateJobResponse{}
	return response.FromJob(job), nil
}
