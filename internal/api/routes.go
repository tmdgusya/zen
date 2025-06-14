package api

import (
	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	"github.com/tmdgusya/zen/internal/api/handlers"
)

func SetUpRouter(
	jobHandler *handlers.JobHandler,
) *gin.Engine {
	r := gin.Default()

	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	api := r.Group("/api")
	{
		jobs := api.Group("/jobs")
		{
			jobs.POST("/", jobHandler.CreateJob)
			jobs.GET("/:id", jobHandler.GetJob)
		}
	}

	return r
}
