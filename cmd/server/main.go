package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/tmdgusya/zen/internal/app"

	_ "github.com/mattn/go-sqlite3"
	_ "github.com/tmdgusya/zen/docs"
)

func getEnvWithDefault(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

// @title           Zen API
// @version         1.0
// @description     A simple Python script scheduler with zero configuration.
// @termsOfService  http://swagger.io/terms/

// @contact.name   API Support
// @contact.url    http://www.zen.example.com/support
// @contact.email  support@zen.example.com

// @license.name  MIT
// @license.url   https://opensource.org/licenses/MIT

// @host      localhost:8080
// @BasePath  /
func main() {
	dbPath := getEnvWithDefault("ZEN_DB_PATH", "zen.db")
	port := getEnvWithDefault("ZEN_PORT", "8080")

	zenApp, err := app.NewApp(dbPath)

	if err != nil {
		log.Fatalf("Failed to create app: %v", err)
	}
	defer func() {
		if err := zenApp.Shutdown(); err != nil {
			log.Printf("Failed to shutdown app: %v", err)
		}
	}()

	srv := &http.Server{
		Addr:    ":" + port,
		Handler: zenApp.Router,
	}

	log.Println("Zen server is running on port", port)

	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")

	// Graceful shutdown
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Failed to shutdown server: %v", err)
	}

	log.Println("Server shutdown complete")
}
