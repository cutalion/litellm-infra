.PHONY: help up down logs restart status clean setup test health

# Default target
help:
	@echo "LiteLLM Infrastructure Management"
	@echo "================================"
	@echo "Available commands:"
	@echo "  make setup      - Initial setup (copy env template)"
	@echo "  make up         - Start all services in development mode"
	@echo "  make up-prod    - Start all services in production mode"
	@echo "  make down       - Stop all services"
	@echo "  make restart    - Restart all services"
	@echo "  make logs       - View logs (all services)"
	@echo "  make logs-f     - Follow logs (all services)"
	@echo "  make status     - Show service status"
	@echo "  make health     - Check service health"
	@echo "  make test       - Test API endpoint"
	@echo "  make clean      - Clean up volumes and data"

# Setup environment
setup:
	@if [ ! -f .env ]; then \
		cp env.template .env; \
		echo "Created .env file. Please edit it with your configuration."; \
	else \
		echo ".env file already exists."; \
	fi
	@mkdir -p logs

# Start services
up:
	docker-compose up -d
	@echo "Services started in development mode"
	@echo "Access the API at: http://localhost:8080"

# Start in production mode
up-prod:
	docker-compose -f docker-compose.yml up -d
	@echo "Services started in production mode"

# Stop services
down:
	docker-compose down

# Restart services
restart:
	docker-compose restart

# View logs
logs:
	docker-compose logs

# Follow logs
logs-f:
	docker-compose logs -f

# Show specific service logs
logs-%:
	docker-compose logs -f $*

# Show service status
status:
	docker-compose ps

# Health check
health:
	@echo "Checking LiteLLM health..."
	@curl -s http://localhost:4000/health | jq '.' || echo "LiteLLM not responding"
	@echo "\nChecking Caddy proxy health..."
	@curl -s http://localhost:8080/health | jq '.' || echo "Caddy proxy not responding"

# Test API
test:
	@echo "Testing API endpoint..."
	@curl -X POST http://localhost:8080/v1/chat/completions \
		-H "Authorization: Bearer dev-master-key-123456789" \
		-H "Content-Type: application/json" \
		-d '{"model": "gpt-3.5-turbo", "messages": [{"role": "user", "content": "Say hello"}]}' \
		| jq '.'

# Pull latest images
pull:
	docker-compose pull

# Build services (if custom images)
build:
	docker-compose build

# Clean up
clean:
	@echo "Warning: This will remove all data!"
	@read -p "Are you sure? (y/N) " confirm && [ "$$confirm" = "y" ] || exit 1
	docker-compose down -v
	rm -rf logs/

# Validate configuration
validate:
	@echo "Validating docker-compose configuration..."
	docker-compose config > /dev/null
	@echo "Configuration is valid!"

# Show environment
env:
	@if [ -f .env ]; then \
		echo "Current environment variables:"; \
		cat .env | grep -v '^#' | grep -v '^$$'; \
	else \
		echo ".env file not found. Run 'make setup' first."; \
	fi 
