# Sales API Service

The API service is the **ingestion layer** of the Sales Signal Processing Platform. It receives sales events from external clients, validates them, and queues them for asynchronous processing.

## Architecture Role

```
External Clients
       │
       ▼
┌──────────────┐
│   API        │  ◄── YOU ARE HERE
│   Service    │
└──────┬───────┘
       │
       ▼
    Redis Queue
       │
       ▼
    Worker Service
```

## Features

- **REST API** for sales event ingestion
- **Request Validation** using class-validator decorators
- **Queue Publishing** via Bull/Redis
- **Health Checks** for Kubernetes probes
- **Structured Logging** for observability

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/events` | Submit a sales event for processing |
| `GET` | `/events/:id` | Retrieve a processed event |
| `GET` | `/health` | Liveness probe endpoint |
| `GET` | `/ready` | Readiness probe endpoint |

## Project Structure

```
src/
├── main.ts                 # Application entry point
├── app.module.ts           # Root module
├── events/
│   ├── events.module.ts    # Events feature module
│   ├── events.controller.ts# HTTP request handlers
│   ├── events.service.ts   # Business logic
│   └── dto/
│       └── create-event.dto.ts # Request validation
├── health/
│   ├── health.module.ts    # Health check module
│   └── health.controller.ts# Health endpoints
└── common/
    ├── filters/            # Exception filters
    ├── interceptors/       # Logging interceptors
    └── pipes/              # Validation pipes
```

## Environment Variables

```bash
# Application
PORT=3000
NODE_ENV=development

# Redis (Queue)
REDIS_HOST=localhost
REDIS_PORT=6379

# PostgreSQL (Read-only for API)
DATABASE_URL=postgresql://user:pass@localhost:5432/sspp

# Logging
LOG_LEVEL=info
```

## Local Development

### Prerequisites

- Node.js 18+
- pnpm
- Redis running locally
- PostgreSQL running locally

### Setup

```bash
# Install dependencies
pnpm install

# Copy environment file
cp .env.example .env

# Start in development mode (with hot reload)
pnpm run start:dev

# Run tests
pnpm run test

# Build for production
pnpm run build
```

### With Docker

```bash
# Build image
docker build -t sspp-api .

# Run container
docker run -p 3000:3000 --env-file .env sspp-api
```

### With Docker Compose (from repo root)

```bash
docker-compose up api
```

## Docker Build

The Dockerfile uses a **multi-stage build** for optimized production images:

```dockerfile
# Stage 1: Build
FROM node:18-alpine AS builder
# Install dependencies and build TypeScript

# Stage 2: Production
FROM node:18-alpine AS production
# Copy only built artifacts and production dependencies
```

Benefits:
- Smaller image size (~150MB vs ~800MB)
- No dev dependencies in production
- Faster deployment times

## Kubernetes Deployment

The API service is deployed with:

- **Deployment**: 2-5 replicas with rolling updates
- **Service**: ClusterIP for internal traffic
- **Ingress**: External access via NGINX ingress
- **HPA**: Auto-scaling based on CPU/memory
- **ConfigMap**: Environment configuration
- **Secrets**: Sensitive credentials

See:
- [infrastructure/k8s/base/api-deployment.yaml](../../infrastructure/k8s/base/api-deployment.yaml)
- [infrastructure/charts/api/](../../infrastructure/charts/api/)

## Health Checks

### Liveness Probe (`/health`)

Returns 200 if the process is running. Used by Kubernetes to restart unhealthy pods.

```json
{
  "status": "ok",
  "timestamp": "2026-01-03T12:00:00Z"
}
```

### Readiness Probe (`/ready`)

Returns 200 if the service can accept traffic (Redis connected, DB accessible).

```json
{
  "status": "ready",
  "checks": {
    "redis": "connected",
    "database": "connected"
  }
}
```

## Testing

```bash
# Unit tests
pnpm run test

# E2E tests
pnpm run test:e2e

# Test coverage
pnpm run test:cov
```

## Related Resources

| Resource | Location |
|----------|----------|
| Worker Service | [../worker/](../worker/) |
| Helm Chart | [infrastructure/charts/api/](../../infrastructure/charts/api/) |
| K8s Manifests | [infrastructure/k8s/base/](../../infrastructure/k8s/base/) |
| CI/CD Pipeline | [.github/workflows/api.yml](../../.github/workflows/api.yml) |
| Docker Compose | [docker-compose.yml](../../docker-compose.yml) |
