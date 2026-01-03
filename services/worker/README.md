# Signal Processing Worker

The Worker service is the **processing layer** of the Sales Signal Processing Platform. It consumes events from the Redis queue, applies business logic, and persists results to PostgreSQL and Elasticsearch.

## Architecture Role

```
    API Service
         │
         ▼
    Redis Queue
         │
         ▼
┌────────────────┐
│    Worker      │  ◄── YOU ARE HERE
│    Service     │
└───────┬────────┘
        │
   ┌────┴────┐
   ▼         ▼
PostgreSQL  Elasticsearch
```

## Features

- **Queue Consumer** using Bull for reliable job processing
- **Signal Generation** from raw sales events
- **Data Persistence** to PostgreSQL via TypeORM
- **Search Indexing** to Elasticsearch
- **Retry Logic** for transient failures
- **Graceful Shutdown** for zero message loss

## Processing Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     Job Processing                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Consume Job       ──►  Pull event from Redis queue      │
│          │                                                   │
│          ▼                                                   │
│  2. Validate Event    ──►  Schema validation                │
│          │                                                   │
│          ▼                                                   │
│  3. Process Signal    ──►  Apply business logic             │
│          │                                                   │
│          ▼                                                   │
│  4. Persist to DB     ──►  Insert into PostgreSQL           │
│          │                                                   │
│          ▼                                                   │
│  5. Index for Search  ──►  Index into Elasticsearch         │
│          │                                                   │
│          ▼                                                   │
│  6. Acknowledge Job   ──►  Remove from queue                │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

```
src/
├── main.ts                 # Application entry point
├── worker.module.ts        # Root module
├── processors/
│   ├── event.processor.ts  # Bull job processor
│   └── signal.processor.ts # Signal generation logic
├── services/
│   ├── database.service.ts # PostgreSQL operations
│   └── search.service.ts   # Elasticsearch operations
├── entities/
│   └── signal.entity.ts    # TypeORM entity
└── common/
    ├── logger/             # Structured logging
    └── utils/              # Helper functions
```

## Environment Variables

```bash
# Application
NODE_ENV=development

# Redis (Queue)
REDIS_HOST=localhost
REDIS_PORT=6379

# PostgreSQL
DATABASE_URL=postgresql://user:pass@localhost:5432/sspp

# Elasticsearch
ELASTICSEARCH_URL=http://localhost:9200

# Worker Configuration
CONCURRENCY=5
MAX_RETRIES=3
RETRY_DELAY=5000
```

## Local Development

### Prerequisites

- Node.js 18+
- pnpm
- Redis running locally
- PostgreSQL running locally
- Elasticsearch running locally

### Setup

```bash
# Install dependencies
pnpm install

# Copy environment file
cp .env.example .env

# Start in development mode
pnpm run start:dev

# Run tests
pnpm run test

# Build for production
pnpm run build
```

### With Docker Compose (from repo root)

```bash
# Start all dependencies
docker-compose up -d redis postgres elasticsearch

# Start worker
docker-compose up worker
```

## Scaling Strategy

The worker service scales based on **queue depth**, not HTTP traffic:

| Metric | Scaling Action |
|--------|----------------|
| Queue depth > 100 | Scale up |
| Queue depth < 10 | Scale down |
| Processing latency > 5s | Scale up |
| CPU > 80% | Scale up |

### KEDA Configuration

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: worker-scaledobject
spec:
  scaleTargetRef:
    name: worker
  minReplicaCount: 1
  maxReplicaCount: 10
  triggers:
    - type: redis
      metadata:
        address: redis:6379
        listName: bull:events:wait
        listLength: "50"
```

See: [infrastructure/k8s/advanced/keda-scaledobject.yaml](../../infrastructure/k8s/advanced/)

## Job Retry Logic

Failed jobs are retried with exponential backoff:

| Attempt | Delay |
|---------|-------|
| 1 | 5 seconds |
| 2 | 25 seconds |
| 3 | 125 seconds |
| 4+ | Move to dead letter queue |

```typescript
// Bull job options
{
  attempts: 3,
  backoff: {
    type: 'exponential',
    delay: 5000
  }
}
```

## Graceful Shutdown

The worker implements graceful shutdown to prevent message loss:

1. Stop accepting new jobs
2. Wait for in-progress jobs to complete (30s timeout)
3. Close database connections
4. Exit process

```typescript
process.on('SIGTERM', async () => {
  await queue.close();
  await dbConnection.close();
  process.exit(0);
});
```

## Kubernetes Deployment

The worker is deployed with:

- **Deployment**: 1-10 replicas based on queue depth
- **KEDA ScaledObject**: Event-driven autoscaling
- **ConfigMap**: Environment configuration
- **Secrets**: Database and Redis credentials
- **PodDisruptionBudget**: Ensure availability during updates

See:
- [infrastructure/k8s/base/worker-deployment.yaml](../../infrastructure/k8s/base/worker-deployment.yaml)
- [infrastructure/charts/worker/](../../infrastructure/charts/worker/)

## Monitoring

### Key Metrics

| Metric | Description |
|--------|-------------|
| `jobs_processed_total` | Total jobs processed |
| `jobs_failed_total` | Total job failures |
| `job_duration_seconds` | Processing time per job |
| `queue_depth` | Current queue size |

### Alerts

```yaml
# High failure rate
alert: WorkerHighFailureRate
expr: rate(jobs_failed_total[5m]) > 0.1
for: 5m
```

See: [infrastructure/k8s/advanced/alerts.yaml](../../infrastructure/k8s/advanced/alerts.yaml)

## Testing

```bash
# Unit tests
pnpm run test

# Integration tests (requires Redis, PostgreSQL, ES)
pnpm run test:integration

# Test coverage
pnpm run test:cov
```

## Related Resources

| Resource | Location |
|----------|----------|
| API Service | [../api/](../api/) |
| Helm Chart | [infrastructure/charts/worker/](../../infrastructure/charts/worker/) |
| K8s Manifests | [infrastructure/k8s/base/](../../infrastructure/k8s/base/) |
| CI/CD Pipeline | [.github/workflows/worker.yml](../../.github/workflows/worker.yml) |
| KEDA Scaling | [infrastructure/k8s/advanced/](../../infrastructure/k8s/advanced/) |
