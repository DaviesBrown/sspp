# Makefile for Sales Signal Processing Platform

.PHONY: help setup up down logs test build deploy clean

# Default target
help:
	@echo "════════════════════════════════════════════════════════════════"
	@echo "  Sales Signal Processing Platform (SSPP) - Makefile"
	@echo "════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "LOCAL DEVELOPMENT:"
	@echo "  setup          Install dependencies for all services"
	@echo "  up             Start infrastructure (Postgres, Redis, ES)"
	@echo "  down           Stop infrastructure"
	@echo "  up-local       Start full stack with Docker"
	@echo "  down-local     Stop full stack"
	@echo "  dev-api        Run API in dev mode"
	@echo "  dev-worker     Run Worker in dev mode"
	@echo "  logs           View infrastructure logs"
	@echo "  logs-local     View full stack logs"
	@echo ""
	@echo "TESTING:"
	@echo "  test           Run all tests"
	@echo "  test-api       Run API tests"
	@echo "  test-worker    Run Worker tests"
	@echo "  quick-test     Test running system"
	@echo "  lint           Lint all code"
	@echo ""
	@echo "DOCKER:"
	@echo "  build          Build Docker images"
	@echo "  build-dockerhub DOCKER_USERNAME=x TAG=v1.0.0"
	@echo "  push-dockerhub  Push to DockerHub"
	@echo ""
	@echo "KUBERNETES:"
	@echo "  deploy-dev     Deploy to dev (Kustomize)"
	@echo "  deploy-staging Deploy to staging"
	@echo "  deploy-prod    Deploy to production"
	@echo "  deploy-argocd  Deploy via ArgoCD GitOps"
	@echo ""
	@echo "INFRASTRUCTURE:"
	@echo "  tf-init        Initialize Terraform"
	@echo "  tf-plan        Plan infrastructure changes"
	@echo "  tf-apply       Apply infrastructure"
	@echo "  install-tools  Install cluster tools (ArgoCD, Prometheus, etc)"
	@echo "  port-forward   Open dashboards locally"
	@echo ""
	@echo "DATABASE:"
	@echo "  db-migrate     Run database migrations"
	@echo "  db-seed        Seed sample data"
	@echo "  db-shell       Open PostgreSQL shell"
	@echo ""
	@echo "UTILITIES:"
	@echo "  status         Check system status"
	@echo "  clean          Clean up containers and volumes"
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
	cd services/api && pnpm test

# Test worker service
test-worker:
	@echo "Running Worker tests..."
	cd services/worker && pnpm test

# Build Docker images locally
build:
	@echo "Building Docker images locally..."
	docker-compose -f docker-compose.yml build
	@echo "✓ Build complete!"

# Build for local development (quick build)
build-local:
	@echo "Building services for local development..."
	docker-compose -f docker-compose.yml build --parallel api worker
	@echo "✓ Services built!"
	@echo ""
	@echo "Run 'make up-local' to start everything"

# Build and run everything locally
up-local:
	@echo "Building and starting full stack locally..."
	docker-compose -f docker-compose.yml up -d --build
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
	docker-compose -f docker-compose.yml down

# View logs from local stack
logs-local:
	docker-compose -f docker-compose.yml logs -f

# Restart local services
restart-local:
	@echo "Restarting services..."
	docker-compose -f docker-compose.yml restart api worker
	@echo "✓ Services restarted"

# Rebuild and restart a specific service
rebuild-api:
	@echo "Rebuilding API service..."
	docker-compose -f docker-compose.yml build api
	docker-compose -f docker-compose.yml up -d api
	@echo "✓ API rebuilt and restarted"

rebuild-worker:
	@echo "Rebuilding Worker service..."
	docker-compose -f docker-compose.yml build worker
	docker-compose -f docker-compose.yml up -d worker
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

# Deploy to Kubernetes (using Kustomize)
deploy-dev:
	@echo "Deploying to development environment..."
	kubectl apply -k infrastructure/k8s/overlays/dev
	@echo "✓ Deployed to dev!"

deploy-staging:
	@echo "Deploying to staging environment..."
	kubectl apply -k infrastructure/k8s/overlays/staging
	@echo "✓ Deployed to staging!"

deploy-prod:
	@echo "Deploying to production environment..."
	@read -p "Are you sure you want to deploy to PRODUCTION? [y/N] " confirm && [ "$$confirm" = "y" ]
	kubectl apply -k infrastructure/k8s/overlays/prod
	@echo "✓ Deployed to production!"

# Deploy via ArgoCD (GitOps)
deploy-argocd:
	@echo "Deploying via ArgoCD..."
	kubectl apply -f infrastructure/argocd/root-app.yaml
	@echo "✓ ArgoCD will sync automatically"

# Legacy deploy (for backwards compatibility)
deploy-k8s: deploy-dev

# ═══════════════════════════════════════════════════════════════
# TERRAFORM / INFRASTRUCTURE
# ═══════════════════════════════════════════════════════════════

tf-init:
	@echo "Initializing Terraform..."
	cd infrastructure/terraform && terraform init

tf-plan:
	@echo "Planning infrastructure changes..."
	cd infrastructure/terraform && terraform plan

tf-apply:
	@echo "Applying infrastructure..."
	cd infrastructure/terraform && terraform apply

tf-destroy:
	@echo "Destroying infrastructure..."
	@read -p "Are you sure? This will destroy all resources! [y/N] " confirm && [ "$$confirm" = "y" ]
	cd infrastructure/terraform && terraform destroy

# Install cluster tools
install-tools:
	@echo "Installing cluster tools..."
	./infrastructure/scripts/install-tools.sh

# Port forward dashboards
port-forward:
	@echo "Starting port forwards for dashboards..."
	./infrastructure/scripts/port-forward-dashboards.sh

# Check cluster health
check-health:
	@echo "Checking cluster health..."
	./infrastructure/scripts/check-health.sh

# ═══════════════════════════════════════════════════════════════
# CLEANUP
# ═══════════════════════════════════════════════════════════════

# Clean up
clean:
	@echo "Cleaning up..."
	docker-compose down -v
	docker system prune -f
	@echo "Cleanup complete!"

# ═══════════════════════════════════════════════════════════════
# DEVELOPMENT
# ═══════════════════════════════════════════════════════════════

# Development targets
dev-api:
	cd services/api && pnpm run start:dev

dev-worker:
	cd services/worker && pnpm run start:dev

# Run full stack with Docker Compose
up-full:
	@echo "Starting full stack (infrastructure + services)..."
	DOCKER_REGISTRY=$(DOCKER_REGISTRY) VERSION=$(VERSION) docker-compose -f docker-compose.yml up -d
	@echo "Waiting for services..."
	@sleep 15
	@echo "Running migrations..."
	docker exec -i sspp-postgres psql -U sspp_user -d sales_signals < infrastructure/database/init.sql
	@echo "Full stack ready!"
	@echo "API: http://localhost:3000/api/v1"
	@echo "API Docs: http://localhost:3000/api/docs"

down-full:
	@echo "Stopping full stack..."
	docker-compose -f docker-compose.yml down

# ═══════════════════════════════════════════════════════════════
# LINTING & FORMATTING
# ═══════════════════════════════════════════════════════════════

# Lint code
lint:
	cd services/api && pnpm run lint
	cd services/worker && pnpm run lint

# Format code
format:
	cd services/api && pnpm run format
	cd services/worker && pnpm run format

# ═══════════════════════════════════════════════════════════════
# DATABASE
# ═══════════════════════════════════════════════════════════════

# Database operations
db-migrate:
	docker exec -i sspp-postgres psql -U sspp_user -d sales_signals < infrastructure/database/init.sql

db-seed:
	docker exec -i sspp-postgres psql -U sspp_user -d sales_signals < infrastructure/database/seed.sql

db-shell:
	docker exec -it sspp-postgres psql -U sspp_user -d sales_signals

# ═══════════════════════════════════════════════════════════════
# OTHER SERVICES
# ═══════════════════════════════════════════════════════════════

# Redis operations
redis-shell:
	docker exec -it sspp-redis redis-cli

# Elasticsearch operations
es-health:
	curl http://localhost:9200/_cluster/health?pretty

# ═══════════════════════════════════════════════════════════════
# TESTING & DIAGNOSTICS
# ═══════════════════════════════════════════════════════════════

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
	@docker-compose -f docker-compose.yml ps
