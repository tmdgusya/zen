package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/tmdgusya/zen/internal/service"
	"github.com/tmdgusya/zen/internal/types"
)

type JobHandler struct {
	jobService *service.JobService
}

func NewJobHandler(jobService *service.JobService) *JobHandler {
	return &JobHandler{jobService: jobService}
}

// CreateJob godoc
// @Summary      Create a new job
// @Description  Create a new Python script job with schedule
// @Tags         jobs
// @Accept       json
// @Produce      json
// @Param        job  body      types.CreateJobRequest  true  "Job creation request"
// @Success      201  {object}  types.CreateJobResponse       "Job created successfully"
// @Failure      400  {object}  map[string]string       "Bad request"
// @Failure      500  {object}  map[string]string       "Internal server error"
// @Router       /api/jobs [post]
func (h *JobHandler) CreateJob(c *gin.Context) {
	var req types.CreateJobRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	job, err := h.jobService.CreateJob(c.Request.Context(), &req)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, job)
}

// GetJob godoc
// @Summary      Get a job by ID
// @Description  Get a job by its unique identifier
// @Tags         jobs
// @Accept       json
// @Produce      json
// @Param        id  path      int  true  "Job ID"
// @Success      200  {object}  types.GetJobResponse       "Job retrieved successfully"
// @Failure      400  {object}  map[string]string       "Bad request"
// @Failure      404  {object}  map[string]string       "Job not found"
// @Failure      500  {object}  map[string]string       "Internal server error"
// @Router       /api/jobs/{id} [get]
func (h *JobHandler) GetJob(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid job ID"})
		return
	}

	job, err := h.jobService.GetJob(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, job)
}
