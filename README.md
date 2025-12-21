# Sales Signal Processing Platform

A production-grade, cloud-native backend platform for processing sales activity events.

## Architecture

```
External Client → API Service → Redis Queue → Worker → PostgreSQL/Elasticsearch
```

## Components

- **Sales API Service**: NestJS-based API for event ingestion
- **Signal Processing Worker**: Async event processor
- **Redis**: Message queue and cache
- **PostgreSQL**: Primary data store
- **Elasticsearch**: Search and analytics
- **Kubernetes**: Container orchestration
- **Terraform**: Infrastructure as Code

## Quick Start

### Prerequisites

- Node.js 18+
- Docker & Docker Compose
- Kubernetes (kubectl)
- Terraform
- Linode CLI (for cloud deployment)

### Local Development

```bash
# Install dependencies
cd services/api && npm install
cd ../worker && npm install

# Start local stack
docker-compose up -d

# Run API service
cd services/api && npm run start:dev

# Run worker service
cd services/worker && npm run start:dev
```

### Testing

```bash
# Unit tests
npm test

# Integration tests
npm run test:e2e

# Load tests
npm run test:load
```

### Deployment

```bash
# Initialize Terraform
cd infrastructure/terraform
terraform init

# Plan infrastructure
terraform plan

# Apply infrastructure
terraform apply

# Deploy to Kubernetes
kubectl apply -f infrastructure/k8s/
```

## Project Structure

```
sspp/
├── services/
│   ├── api/              # NestJS API service
│   └── worker/           # Signal processing worker
├── infrastructure/
│   ├── terraform/        # IaC definitions
│   ├── k8s/             # Kubernetes manifests
│   └── docker/          # Dockerfiles
├── .github/
│   └── workflows/       # CI/CD pipelines
└── docs/                # Documentation
```

## Observability

- **Logs**: Structured JSON logging to stdout
- **Metrics**: Prometheus metrics exposed on `/metrics`
- **Health**: `/health` and `/ready` endpoints

## Security

- Secrets managed via Kubernetes Secrets
- RBAC configured for least privilege
- Network policies enforce isolation
- No secrets in source control

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## License

MIT
