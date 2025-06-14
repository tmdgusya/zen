package app

import (
	"database/sql"
	"log"

	"github.com/gin-gonic/gin"
	"github.com/tmdgusya/zen/internal/api"
	"github.com/tmdgusya/zen/internal/api/handlers"
	"github.com/tmdgusya/zen/internal/repository"
	"github.com/tmdgusya/zen/internal/service"

	gen "github.com/tmdgusya/zen/internal/repository/generated"
)

type Services struct {
	JobService *service.JobService
}

type App struct {
	DB       *sql.DB
	Router   *gin.Engine
	Services *Services
}

func connectDB(dbPath string) (*sql.DB, error) {
	db, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		return nil, err
	}
	return db, nil
}

func NewApp(dbPath string) (*App, error) {
	db, err := connectDB(dbPath)

	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
		return nil, err
	}

	// repository layer
	queries := gen.New(db)
	jobRepo := repository.NewJobRepository(queries)

	// service layer
	jobService := service.NewJobService(jobRepo)

	// api layer
	jobHandler := handlers.NewJobHandler(jobService)

	return &App{
		DB:     db,
		Router: api.SetUpRouter(jobHandler),
		Services: &Services{
			JobService: jobService,
		},
	}, nil
}

func (a *App) Shutdown() error {
	if a.DB != nil {
		a.DB.Close()
	}

	return nil
}
