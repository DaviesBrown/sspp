# Sales Signal Processing Platform (SSPP)

A **production-grade, cloud-native backend platform** for processing sales activity events. This repository includes a complete DevOps infrastructure with Kubernetes, Terraform, GitOps, and comprehensive documentation.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         SSPP Architecture                                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   External Clients                                                                   │
│         │                                                                            │
│         ▼                                                                            │
│   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐                     │
│   │    API         │───▶│    Redis      │───▶│   Worker       │                    │
│   │  (NestJS)      │     │   (Queue)     │     │  (Node.js).    │                    │
│   └─────────────┘     └─────────────┘     └──────┬──────┘                    │
│                                                         │                            │
│                                    ┌──────────────┼──────────────┐              │
│                                    ▼                ▼              ▼               │
│                              PostgreSQL      Redis          Elasticsearch.           │
│                               (Store)       (Cache)         (Search)                 │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

- Node.js 18+ / pnpm
- Docker & Docker Compose
- kubectl (for Kubernetes deployment)
- Terraform (for cloud infrastructure)

### Local Development

```bash
# Install dependencies
make setup

# Start infrastructure (PostgreSQL, Redis, Elasticsearch)
make up

# Run services in development mode
make dev-api      # Terminal 1
make dev-worker   # Terminal 2

# Or run everything with Docker
make up-local
```

### Access Points (Local)

| Service | URL |
|---------|-----|
| API | http://localhost:3000/api/v1 |
| API Docs | http://localhost:3000/api/docs |
| Health Check | http://localhost:3000/api/v1/health |

## Project Structure

```
sspp/
├── services/                    # Application code
│   ├── api/                     # NestJS REST API
│   └── worker/                  # Queue processor
│
├── infrastructure/              # All infrastructure config
│   ├── terraform/               # Cloud provisioning (Linode LKE)
│   ├── k8s/                     # Kubernetes manifests (Kustomize)
│   │   ├── base/                # Base manifests
│   │   ├── overlays/            # Environment patches (dev/staging/prod)
│   │   └── advanced/            # HPA, RBAC, Rollouts
│   ├── charts/                  # Helm charts
│   ├── argocd/                  # GitOps applications
│   ├── database/                # SQL init/migrations
│   └── scripts/                 # Tool installation scripts
│
├── .github/workflows/           # CI/CD pipelines
├── docker-compose.yml           # Local infrastructure
└── docker-compose.full.yml      # Full local stack
```

## Deployment Options

### Option 1: Kustomize (Direct kubectl)

```bash
# Development
kubectl apply -k infrastructure/k8s/overlays/dev

# Production
kubectl apply -k infrastructure/k8s/overlays/prod
```

### Option 2: GitOps with ArgoCD

```bash
# Install ArgoCD
./infrastructure/scripts/install-tools.sh 1

# Deploy via App of Apps
kubectl apply -f infrastructure/argocd/root-app.yaml
```

### Option 3: Helm Charts

```bash
helm install sspp-api infrastructure/charts/api -n sspp
helm install sspp-worker infrastructure/charts/worker -n sspp
```

## Infrastructure Provisioning

```bash
# Set Linode token
export TF_VAR_linode_token="your-token"

# Provision cluster
cd infrastructure/terraform
terraform init && terraform apply

# Get kubeconfig
terraform output -raw kubeconfig > ~/.kube/sspp-config
export KUBECONFIG=~/.kube/sspp-config
```

## Makefile Commands

```bash
make help          # Show all commands
make setup         # Install dependencies
make up            # Start infrastructure only
make up-local      # Start full stack with Docker
make down-local    # Stop full stack
make test          # Run all tests
make deploy-dev    # Deploy to dev environment
make deploy-prod   # Deploy to production
make status        # Check service status
make quick-test    # Test the running system
```

## Observability

| Tool | Purpose | Access |
|------|---------|--------|
| Prometheus | Metrics | `make port-forward` → localhost:9090 |
| Grafana | Dashboards | `make port-forward` → localhost:3000 |
| Loki | Logs | Integrated with Grafana |
| ArgoCD | Deployments | `make port-forward` → localhost:8080 |

Install all tools:
```bash
./infrastructure/scripts/install-tools.sh 6
./infrastructure/scripts/port-forward-dashboards.sh
```

## Documentation

This project includes a **10-part DevOps article series** documenting the journey from manual deployment to production GitOps:
[Start here](https://dev.to/daviesbrown/part-1-the-default-way-putting-an-app-on-a-server-and-why-it-breaks-2a5j)

## Security

- Secrets managed via Kubernetes Secrets / Sealed Secrets
- RBAC configured for least privilege access
- Network policies enforce pod isolation
- No secrets committed to source control

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## License

MIT

