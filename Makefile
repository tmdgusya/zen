# Zen Makefile
# Variables
APP_NAME=zen
MAIN_PATH=cmd/server/main.go
DOCS_PATH=./docs
DB_PATH=zen.db
PORT=8080

# Colors for output
CYAN=\033[0;36m
GREEN=\033[0;32m
YELLOW=\033[0;33m
RED=\033[0;31m
NC=\033[0m # No Color

.PHONY: help dev build run clean docs test lint install deps setup docker

# Default target
.DEFAULT_GOAL := help

## Help
help: ## Show this help message
	@echo "$(CYAN)Zen - Python Script Scheduler$(NC)"
	@echo "$(CYAN)==============================$(NC)"
	@echo ""
	@echo "$(GREEN)Available commands:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(CYAN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

## Development
dev: ## Generate docs and start development server
	@echo "$(YELLOW)🔄 Generating Swagger docs...$(NC)"
	@swag init -g $(MAIN_PATH) -o $(DOCS_PATH)
	@echo "$(GREEN)✅ Docs generated$(NC)"
	@echo "$(YELLOW)🚀 Starting development server...$(NC)"
	@echo "$(CYAN)📖 Swagger UI: http://localhost:$(PORT)/swagger/index.html$(NC)"
	@echo "$(CYAN)🏥 Health Check: http://localhost:$(PORT)/health$(NC)"
	@go run $(MAIN_PATH)

dev-watch: ## Start development server with hot reload (requires air)
	@echo "$(YELLOW)🔄 Starting development server with hot reload...$(NC)"
	@if command -v air >/dev/null 2>&1; then \
		air; \
	else \
		echo "$(RED)❌ Air not installed. Install with: go install github.com/cosmtrek/air@latest$(NC)"; \
		echo "$(YELLOW)🔄 Falling back to regular dev mode...$(NC)"; \
		make dev; \
	fi

## Building
build: docs ## Build the application
	@echo "$(YELLOW)🔨 Building $(APP_NAME)...$(NC)"
	@go build -o bin/$(APP_NAME) $(MAIN_PATH)
	@echo "$(GREEN)✅ Build complete: bin/$(APP_NAME)$(NC)"

build-linux: docs ## Build for Linux
	@echo "$(YELLOW)🔨 Building $(APP_NAME) for Linux...$(NC)"
	@GOOS=linux GOARCH=amd64 go build -o bin/$(APP_NAME)-linux-amd64 $(MAIN_PATH)
	@echo "$(GREEN)✅ Linux build complete: bin/$(APP_NAME)-linux-amd64$(NC)"

build-windows: docs ## Build for Windows
	@echo "$(YELLOW)🔨 Building $(APP_NAME) for Windows...$(NC)"
	@GOOS=windows GOARCH=amd64 go build -o bin/$(APP_NAME)-windows-amd64.exe $(MAIN_PATH)
	@echo "$(GREEN)✅ Windows build complete: bin/$(APP_NAME)-windows-amd64.exe$(NC)"

build-mac: docs ## Build for macOS
	@echo "$(YELLOW)🔨 Building $(APP_NAME) for macOS...$(NC)"
	@GOOS=darwin GOARCH=amd64 go build -o bin/$(APP_NAME)-darwin-amd64 $(MAIN_PATH)
	@echo "$(GREEN)✅ macOS build complete: bin/$(APP_NAME)-darwin-amd64$(NC)"

build-all: build-linux build-windows build-mac ## Build for all platforms
	@echo "$(GREEN)✅ All builds complete!$(NC)"

## Running
run: build ## Build and run the application
	@echo "$(YELLOW)🚀 Running $(APP_NAME)...$(NC)"
	@./bin/$(APP_NAME)

## Documentation
docs: ## Generate Swagger documentation
	@echo "$(YELLOW)📚 Generating Swagger documentation...$(NC)"
	@if command -v swag >/dev/null 2>&1; then \
		swag init -g $(MAIN_PATH) -o $(DOCS_PATH); \
		echo "$(GREEN)✅ Documentation generated in $(DOCS_PATH)$(NC)"; \
	else \
		echo "$(RED)❌ swag not found. Installing...$(NC)"; \
		go install github.com/swaggo/swag/cmd/swag@latest; \
		swag init -g $(MAIN_PATH) -o $(DOCS_PATH); \
		echo "$(GREEN)✅ Documentation generated in $(DOCS_PATH)$(NC)"; \
	fi

docs-serve: docs ## Generate docs and serve only documentation
	@echo "$(YELLOW)📖 Serving documentation at http://localhost:$(PORT)/swagger/index.html$(NC)"
	@go run $(MAIN_PATH)

## Database
db-reset: ## Reset the database (delete and recreate)
	@echo "$(YELLOW)🗑️  Resetting database...$(NC)"
	@rm -f $(DB_PATH)
	@echo "$(GREEN)✅ Database reset complete$(NC)"

db-backup: ## Backup the database
	@echo "$(YELLOW)💾 Backing up database...$(NC)"
	@cp $(DB_PATH) $(DB_PATH).backup.$(shell date +%Y%m%d_%H%M%S)
	@echo "$(GREEN)✅ Database backed up$(NC)"

db-shell: ## Open SQLite shell
	@echo "$(YELLOW)🐚 Opening database shell...$(NC)"
	@sqlite3 $(DB_PATH)

db-inspect: ## Show database tables and schema
	@echo "$(CYAN)📊 Database Schema:$(NC)"
	@sqlite3 $(DB_PATH) ".schema"
	@echo ""
	@echo "$(CYAN)📋 Tables:$(NC)"
	@sqlite3 $(DB_PATH) ".tables"
	@echo ""
	@echo "$(CYAN)📈 Row Counts:$(NC)"
	@sqlite3 $(DB_PATH) "SELECT 'jobs: ' || COUNT(*) FROM jobs; SELECT 'job_executions: ' || COUNT(*) FROM job_executions;"

## Testing
test: ## Run tests
	@echo "$(YELLOW)🧪 Running tests...$(NC)"
	@go test -v ./...

test-coverage: ## Run tests with coverage
	@echo "$(YELLOW)🧪 Running tests with coverage...$(NC)"
	@go test -v -cover ./...
	@go test -coverprofile=coverage.out ./...
	@go tool cover -html=coverage.out -o coverage.html
	@echo "$(GREEN)✅ Coverage report generated: coverage.html$(NC)"

test-integration: ## Run integration tests
	@echo "$(YELLOW)🧪 Running integration tests...$(NC)"
	@go test -v -tags=integration ./...

## Code Quality
lint: ## Run linter
	@echo "$(YELLOW)🔍 Running linter...$(NC)"
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run; \
	else \
		echo "$(RED)❌ golangci-lint not installed. Install with:$(NC)"; \
		echo "$(CYAN)curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b \$$(go env GOPATH)/bin v1.54.2$(NC)"; \
		echo "$(YELLOW)🔄 Running go vet instead...$(NC)"; \
		go vet ./...; \
	fi

fmt: ## Format code
	@echo "$(YELLOW)🎨 Formatting code...$(NC)"
	@go fmt ./...
	@echo "$(GREEN)✅ Code formatted$(NC)"

## Dependencies
deps: ## Download dependencies
	@echo "$(YELLOW)📦 Downloading dependencies...$(NC)"
	@go mod download
	@echo "$(GREEN)✅ Dependencies downloaded$(NC)"

tidy: ## Tidy dependencies
	@echo "$(YELLOW)🧹 Tidying dependencies...$(NC)"
	@go mod tidy
	@echo "$(GREEN)✅ Dependencies tidied$(NC)"

vendor: ## Create vendor directory
	@echo "$(YELLOW)📦 Creating vendor directory...$(NC)"
	@go mod vendor
	@echo "$(GREEN)✅ Vendor directory created$(NC)"

## Installation
install: build ## Install the application to GOPATH/bin
	@echo "$(YELLOW)📦 Installing $(APP_NAME)...$(NC)"
	@go install $(MAIN_PATH)
	@echo "$(GREEN)✅ $(APP_NAME) installed to $(shell go env GOPATH)/bin$(NC)"

install-tools: ## Install development tools
	@echo "$(YELLOW)🔧 Installing development tools...$(NC)"
	@go install github.com/swaggo/swag/cmd/swag@latest
	@go install github.com/cosmtrek/air@latest
	@echo "$(GREEN)✅ Development tools installed$(NC)"

## Setup
setup: install-tools deps ## Setup development environment
	@echo "$(YELLOW)🛠️  Setting up development environment...$(NC)"
	@make tidy
	@make docs
	@echo "$(GREEN)✅ Development environment ready!$(NC)"
	@echo ""
	@echo "$(CYAN)Next steps:$(NC)"
	@echo "  $(GREEN)make dev$(NC)     - Start development server"
	@echo "  $(GREEN)make test$(NC)    - Run tests"
	@echo "  $(GREEN)make help$(NC)    - Show all available commands"

## Cleanup
clean: ## Clean build artifacts and generated files
	@echo "$(YELLOW)🧹 Cleaning up...$(NC)"
	@rm -rf bin/
	@rm -rf $(DOCS_PATH)/
	@rm -f coverage.out coverage.html
	@echo "$(GREEN)✅ Cleanup complete$(NC)"

clean-all: clean db-reset ## Clean everything including database
	@echo "$(GREEN)✅ Everything cleaned$(NC)"

## Docker
docker-build: ## Build Docker image
	@echo "$(YELLOW)🐳 Building Docker image...$(NC)"
	@docker build -t $(APP_NAME):latest .
	@echo "$(GREEN)✅ Docker image built: $(APP_NAME):latest$(NC)"

docker-run: docker-build ## Build and run Docker container
	@echo "$(YELLOW)🐳 Running Docker container...$(NC)"
	@docker run -p $(PORT):$(PORT) --name $(APP_NAME) --rm $(APP_NAME):latest

docker-stop: ## Stop Docker container
	@echo "$(YELLOW)🐳 Stopping Docker container...$(NC)"
	@docker stop $(APP_NAME)

## Development helpers
api-test: ## Test API endpoints
	@echo "$(YELLOW)🧪 Testing API endpoints...$(NC)"
	@echo "$(CYAN)Health Check:$(NC)"
	@curl -s http://localhost:$(PORT)/health | json_pp || echo "Server not running"
	@echo ""
	@echo "$(CYAN)System Status:$(NC)"
	@curl -s http://localhost:$(PORT)/api/system/status | json_pp || echo "Server not running"

logs: ## Show recent application logs (if running with systemd)
	@journalctl -u $(APP_NAME) -f --no-pager

## Information
info: ## Show project information
	@echo "$(CYAN)Zen Project Information$(NC)"
	@echo "$(CYAN)=======================$(NC)"
	@echo "App Name: $(APP_NAME)"
	@echo "Main Path: $(MAIN_PATH)"
	@echo "Database: $(DB_PATH)"
	@echo "Port: $(PORT)"
	@echo "Go Version: $(shell go version)"
	@echo "Git Branch: $(shell git branch --show-current 2>/dev/null || echo 'Not a git repository')"
	@echo "Git Commit: $(shell git rev-parse --short HEAD 2>/dev/null || echo 'Not a git repository')"
	@echo ""
	@echo "$(GREEN)Quick Start:$(NC)"
	@echo "  make setup    # First time setup"
	@echo "  make dev      # Start development"