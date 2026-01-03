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
- **Prometheus Metrics** for observability and monitoring
- **Structured Logging** for debugging and analysis

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/events` | Submit a sales event for processing |
| `GET` | `/events/:id` | Retrieve a processed event |
| `GET` | `/health` | Liveness probe endpoint |
| `GET` | `/ready` | Readiness probe endpoint |
| `GET` | `/metrics` | Prometheus metrics endpoint |

## Prometheus Metrics

The API exposes the following metrics at `/api/v1/metrics`:

### HTTP Metrics
| Metric | Type | Description |
|--------|------|-------------|
| `sspp_api_http_request_duration_seconds` | Histogram | Duration of HTTP requests |
| `sspp_api_http_requests_total` | Counter | Total HTTP requests by method/route/status |

### Event Metrics
| Metric | Type | Description |
|--------|------|-------------|
| `sspp_api_events_received_total` | Counter | Events received by type |
| `sspp_api_events_queued_total` | Counter | Events successfully queued |
| `sspp_api_events_queue_errors_total` | Counter | Events that failed to queue |

### Queue Metrics
| Metric | Type | Description |
|--------|------|-------------|
| `sspp_api_queue_size` | Gauge | Current queue size by state |
| `sspp_api_queue_processing_seconds` | Histogram | Time to add events to queue |

### Infrastructure Metrics
| Metric | Type | Description |
|--------|------|-------------|
| `sspp_api_db_query_duration_seconds` | Histogram | Database query duration |
| `sspp_api_db_connection_pool` | Gauge | DB connection pool status |
| `sspp_api_redis_operation_duration_seconds` | Histogram | Redis operation duration |
| `sspp_api_redis_connection_status` | Gauge | Redis connection status (1=up, 0=down) |

### Default Node.js Metrics
Standard `prom-client` metrics with `sspp_api_` prefix including:
- `sspp_api_process_cpu_*` - CPU usage
- `sspp_api_process_resident_memory_bytes` - Memory usage
- `sspp_api_nodejs_eventloop_lag_*` - Event loop metrics
- `sspp_api_nodejs_gc_*` - Garbage collection metrics

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
