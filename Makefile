# Makefile for Sales Signal Processing Platform

.PHONY: help setup up down logs test build deploy clean

# Default target
help:
	@echo "Sales Signal Processing Platform - Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  setup      - Install dependencies for all services"
	@echo "  up         - Start all infrastructure services"
	@echo "  down       - Stop all infrastructure services"
	@echo "  logs       - View logs from all services"
	@echo "  test       - Run tests for all services"
	@echo "  test-api   - Run API service tests"
	@echo "  test-worker - Run worker service tests"
	@echo "  build      - Build Docker images locally"
	@echo "  build-local - Build services for local development"
	@echo "  up-local   - Build and run full stack locally"
	@echo "  down-local - Stop local full stack"
	@echo "  logs-local - View logs from local stack"
	@echo "  build-dockerhub - Build and tag for DockerHub"
	@echo "  push-dockerhub  - Push images to DockerHub"
	@echo "  release-dockerhub - Build and push to DockerHub"
	@echo "  deploy-k8s - Deploy to Kubernetes"
	@echo "  clean      - Clean up containers and volumes"
	@echo ""

# Setup - Install dependencies
setup:
	@echo "Checking if pnpm is installed..."
	@command -v pnpm >/dev/null 2>&1 || { echo "Installing pnpm..."; npm install -g pnpm; }
	@echo "Installing API dependencies..."
	cd services/api && pnpm install
	@echo "Installing Worker dependencies..."
	cd services/worker && pnpm install
	@echo "Setup complete!"

# Start infrastructure
up:
	@echo "Starting infrastructure services..."
	docker-compose up -d
	@echo "Waiting for services to be ready..."
	@echo "Waiting for PostgreSQL..."
	@until docker exec sspp-postgres pg_isready -U sspp_user -d sales_signals > /dev/null 2>&1; do \
		echo "PostgreSQL is unavailable - waiting..."; \
		sleep 2; \
	done
	@echo "✓ PostgreSQL is ready"
	@echo "Waiting for Redis..."
	@until docker exec sspp-redis redis-cli ping > /dev/null 2>&1; do \
		echo "Redis is unavailable - waiting..."; \
		sleep 1; \
	done
	@echo "✓ Redis is ready"
	@echo "Waiting for Elasticsearch..."
	@sleep 10
	@until curl -s http://localhost:9200/_cluster/health > /dev/null 2>&1; do \
		echo "Elasticsearch is unavailable - waiting..."; \
		sleep 2; \
	done
	@echo "✓ Elasticsearch is ready"
	@echo "Running database migrations..."
	docker exec -i sspp-postgres psql -U sspp_user -d sales_signals < infrastructure/database/init.sql
	@echo "✓ Infrastructure ready!"

# Stop infrastructure
down:
	@echo "Stopping infrastructure services..."
	docker-compose down

# View logs
logs:
	docker-compose logs -f

# Run all tests
test: test-api test-worker

# Test API service
test-api:
	@echo "Running API tests..."
	cd services/api && npm test

# Test worker service
test-worker:
	@echo "Running Worker tests..."
	cd services/worker && npm test

# Build Docker images locally
build:
	@echo "Building Docker images locally..."
	docker-compose -f docker-compose.full.yml build
	@echo "✓ Build complete!"

# Build for local development (quick build)
build-local:
	@echo "Building services for local development..."
	docker-compose -f docker-compose.full.yml build --parallel api worker
	@echo "✓ Services built!"
	@echo ""
	@echo "Run 'make up-local' to start everything"

# Build and run everything locally
up-local:
	@echo "Building and starting full stack locally..."
	docker-compose -f docker-compose.full.yml up -d --build
	@echo "Waiting for services to be ready..."
	@sleep 15
	@echo "Running database migrations..."
	@docker exec sspp-postgres psql -U sspp_user -d sales_signals < infrastructure/database/init.sql 2>/dev/null || echo "Database already initialized"
	@echo ""
	@echo "════════════════════════════════════════"
	@echo "  ✅ Full Stack Running Locally!"
	@echo "════════════════════════════════════════"
	@echo ""
	@echo "Services:"
	@echo "  • API:            http://localhost:3000/api/v1"
	@echo "  • API Docs:       http://localhost:3000/api/docs"
	@echo "  • PostgreSQL:     localhost:5432"
	@echo "  • Redis:          localhost:6379"
	@echo "  • Elasticsearch:  localhost:9200"
	@echo ""
	@echo "Commands:"
	@echo "  • View logs:      make logs-local"
	@echo "  • Stop services:  make down-local"
	@echo "  • Restart:        make restart-local"
	@echo ""

# Stop local full stack
down-local:
	@echo "Stopping local full stack..."
	docker-compose -f docker-compose.full.yml down

# View logs from local stack
logs-local:
	docker-compose -f docker-compose.full.yml logs -f

# Restart local services
restart-local:
	@echo "Restarting services..."
	docker-compose -f docker-compose.full.yml restart api worker
	@echo "✓ Services restarted"

# Rebuild and restart a specific service
rebuild-api:
	@echo "Rebuilding API service..."
	docker-compose -f docker-compose.full.yml build api
	docker-compose -f docker-compose.full.yml up -d api
	@echo "✓ API rebuilt and restarted"

rebuild-worker:
	@echo "Rebuilding Worker service..."
	docker-compose -f docker-compose.full.yml build worker
	docker-compose -f docker-compose.full.yml up -d worker
	@echo "✓ Worker rebuilt and restarted"

# Build with custom tag
build-tag:
	@echo "Building Docker images with tag: $(TAG)"
	DOCKER_REGISTRY=$(REGISTRY) VERSION=$(TAG) docker-compose -f docker-compose.build.yml build
	@echo "Build complete!"

# Build and tag for DockerHub
build-dockerhub:
	@echo "Building images for DockerHub..."
	@if [ -z "$(DOCKER_USERNAME)" ]; then \
		echo "Error: DOCKER_USERNAME not set"; \
		echo "Usage: make build-dockerhub DOCKER_USERNAME=your-username TAG=v1.0.0"; \
		exit 1; \
	fi
	@echo "Building with registry: $(DOCKER_USERNAME)"
	DOCKER_REGISTRY=$(DOCKER_USERNAME) VERSION=$(TAG) docker-compose -f docker-compose.yml build
	docker tag $(DOCKER_USERNAME)/sspp-api:$(TAG) $(DOCKER_USERNAME)/sspp-api:latest
	docker tag $(DOCKER_USERNAME)/sspp-worker:$(TAG) $(DOCKER_USERNAME)/sspp-worker:latest
	@echo "Images built and tagged!"

# Push to DockerHub
push-dockerhub:
	@echo "Pushing images to DockerHub..."
	@if [ -z "$(DOCKER_USERNAME)" ]; then \
		echo "Error: DOCKER_USERNAME not set"; \
		echo "Usage: make push-dockerhub DOCKER_USERNAME=your-username TAG=v1.0.0"; \
		exit 1; \
	fi
	@echo "Logging in to DockerHub..."
	@docker login
	@echo "Pushing $(DOCKER_USERNAME)/sspp-api:$(TAG)..."
	docker push $(DOCKER_USERNAME)/sspp-api:$(TAG)
	docker push $(DOCKER_USERNAME)/sspp-api:latest
	@echo "Pushing $(DOCKER_USERNAME)/sspp-worker:$(TAG)..."
	docker push $(DOCKER_USERNAME)/sspp-worker:$(TAG)
	docker push $(DOCKER_USERNAME)/sspp-worker:latest
	@echo "Push complete!"

# Build and push in one command
release-dockerhub:
	@$(MAKE) build-dockerhub DOCKER_USERNAME=$(DOCKER_USERNAME) TAG=$(TAG)
	@$(MAKE) push-dockerhub DOCKER_USERNAME=$(DOCKER_USERNAME) TAG=$(TAG)

# Deploy to Kubernetes
deploy-k8s:
	@echo "Deploying to Kubernetes..."
	kubectl apply -f infrastructure/k8s/namespace.yaml
	kubectl apply -f infrastructure/k8s/configmap.yaml
	kubectl apply -f infrastructure/k8s/secrets.yaml
	kubectl apply -f infrastructure/k8s/postgres.yaml
	kubectl apply -f infrastructure/k8s/redis.yaml
	kubectl apply -f infrastructure/k8s/elasticsearch.yaml
	kubectl apply -f infrastructure/k8s/api.yaml
	kubectl apply -f infrastructure/k8s/worker.yaml
	@echo "Deployment complete!"

# Clean up
clean:
	@echo "Cleaning up..."
	docker-compose down -v
	docker system prune -f
	@echo "Cleanup complete!"

# Development targets
dev-api:
	cd services/api && npm run start:dev

dev-worker:
	cd services/worker && npm run start:dev

# Run full stack with Docker Compose
up-full:
	@echo "Starting full stack (infrastructure + services)..."
	DOCKER_REGISTRY=$(DOCKER_REGISTRY) VERSION=$(VERSION) docker-compose -f docker-compose.full.yml up -d
	@echo "Waiting for services..."
	@sleep 15
	@echo "Running migrations..."
	docker exec -i sspp-postgres psql -U sspp_user -d sales_signals < infrastructure/database/init.sql
	@echo "Full stack ready!"
	@echo "API: http://localhost:3000/api/v1"
	@echo "API Docs: http://localhost:3000/api/docs"

down-full:
	@echo "Stopping full stack..."
	docker-compose -f docker-compose.full.yml down

# Lint code
lint:
	cd services/api && npm run lint
	cd services/worker && npm run lint

# Format code
format:
	cd services/api && npm run format
	cd services/worker && npm run format

# Database operations
db-migrate:
	docker exec -i sspp-postgres psql -U sspp_user -d sales_signals < infrastructure/database/init.sql

db-seed:
	docker exec -i sspp-postgres psql -U sspp_user -d sales_signals < infrastructure/database/seed.sql

db-shell:
	docker exec -it sspp-postgres psql -U sspp_user -d sales_signals

# Redis operations
redis-shell:
	docker exec -it sspp-redis redis-cli

# Elasticsearch operations
es-health:
	curl http://localhost:9200/_cluster/health?pretty

# Quick test of the system
quick-test:
	@echo "════════════════════════════════════════"
	@echo "  Testing System"
	@echo "════════════════════════════════════════"
	@echo ""
	@echo "1. Testing API health..."
	@curl -s http://localhost:3000/api/v1/health | jq . || echo "❌ API not responding"
	@echo ""
	@echo "2. Sending test event..."
	@curl -s -X POST http://localhost:3000/api/v1/events \
		-H "Content-Type: application/json" \
		-d '{"accountId":"test_001","userId":"user_001","eventType":"email_sent","timestamp":"2024-12-21T10:00:00Z","metadata":{"campaign":"Test"}}' | jq . || echo "❌ Event submission failed"
	@echo ""
	@echo "3. Checking database..."
	@docker exec sspp-postgres psql -U sspp_user -d sales_signals -c "SELECT COUNT(*) as total_signals FROM sales_signals;" 2>/dev/null || echo "❌ Database not accessible"
	@echo ""
	@echo "4. Checking queue..."
	@docker exec sspp-redis redis-cli LLEN sales-events 2>/dev/null || echo "❌ Redis not accessible"
	@echo ""
	@echo "✅ Test complete"

# Status check
status:
	@echo "════════════════════════════════════════"
	@echo "  System Status"
	@echo "════════════════════════════════════════"
	@echo ""
	@docker-compose -f docker-compose.full.yml ps
