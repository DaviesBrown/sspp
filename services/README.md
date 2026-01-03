# Services

This directory contains the core application services for the Sales Signal Processing Platform (SSPP).

## Architecture Context

```
┌─────────────────────────────────────────────────────────────┐
│                    External Clients                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Ingress / Load Balancer                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    ┌─────────────┐                          │
│                    │   API       │ ◄── services/api/        │
│                    │  (NestJS)   │                          │
│                    └──────┬──────┘                          │
│                           │                                  │
│                           ▼                                  │
│                    ┌─────────────┐                          │
│                    │    Redis    │                          │
│                    │   (Queue)   │                          │
│                    └──────┬──────┘                          │
│                           │                                  │
│                           ▼                                  │
│                    ┌─────────────┐                          │
│                    │   Worker    │ ◄── services/worker/     │
│                    │  (Node.js)  │                          │
│                    └──────┬──────┘                          │
│                           │                                  │
│              ┌────────────┼────────────┐                    │
│              ▼            ▼            ▼                    │
│         PostgreSQL     Redis     Elasticsearch              │
└─────────────────────────────────────────────────────────────┘
```

## Services

### [api/](api/)

The **Sales API Service** is the ingestion layer of the platform.

**Responsibilities:**
- Accept and validate incoming sales events via REST API
- Publish events to Redis queue for asynchronous processing
- Expose health (`/health`) and readiness (`/ready`) endpoints
- Provide structured, centralized logging

**Tech Stack:**
- NestJS (Node.js framework)
- TypeScript
- Bull (Redis-based queue)
- Class-validator (request validation)

### [worker/](worker/)

The **Signal Processing Worker** handles asynchronous event processing.

**Responsibilities:**
- Consume events from Redis queue
- Apply business logic to generate sales signals
- Persist processed data to PostgreSQL
- Index signals into Elasticsearch for search/analytics

**Tech Stack:**
- Node.js
- TypeScript
- Bull (queue consumer)
- TypeORM (PostgreSQL)
- Elasticsearch client

## Design Principles

### Separation of Concerns

The API and Worker are **intentionally decoupled**:

| API Service | Worker Service |
|-------------|----------------|
| Handles HTTP requests | Processes queued jobs |
| Stateless | Can be stateful for job context |
| Scales based on traffic | Scales based on queue depth |
| Fast response times | Optimized for throughput |

This separation ensures:
- The API remains responsive during heavy processing loads
- Workers can be scaled independently based on queue backlog
- Failures in processing don't affect event ingestion

### Containerization

Each service includes:
- `Dockerfile` - Multi-stage build for production images
- `.dockerignore` - Excludes unnecessary files from builds
- `.env.example` - Template for environment configuration

## Local Development

```bash
# From repository root
docker-compose up -d

# Or run individual services
cd services/api && pnpm install && pnpm run start:dev
cd services/worker && pnpm install && pnpm run start:dev
```

## Deployment

Services are deployed to Kubernetes via:

1. **Docker Images** → Built by GitHub Actions (`.github/workflows/api.yml`, `worker.yml`)
2. **Helm Charts** → Packaged in `infrastructure/charts/`
3. **Kubernetes Manifests** → Base configs in `infrastructure/k8s/base/`
4. **ArgoCD** → GitOps deployment from `infrastructure/argocd/`

## Related Documentation

| Resource | Location |
|----------|----------|
| API Helm Chart | [infrastructure/charts/api/](../infrastructure/charts/api/) |
| Worker Helm Chart | [infrastructure/charts/worker/](../infrastructure/charts/worker/) |
| K8s Deployments | [infrastructure/k8s/base/](../infrastructure/k8s/base/) |
| Docker Compose | [docker-compose.yml](../docker-compose.yml) |
| CI/CD Workflows | [.github/workflows/](.github/workflows/) |

## Article Reference

This codebase is documented in the DevOps article series:
- **Part 3**: [Containerizing with Docker](../articles/03-docker-containers.md)
- **Part 4**: [Docker Compose for Local Development](../articles/04-docker-compose.md)
