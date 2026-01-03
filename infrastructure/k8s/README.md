# Kubernetes Manifests

Kubernetes manifests for deploying SSPP using Kustomize, with environment-specific overlays.

## How Kubernetes Manifests Fit the Project

```
┌─────────────────────────────────────────────────────────────────────────┐
│                   Kustomize Structure                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   k8s/                    ◄── YOU ARE HERE                              │
│   │                                                                      │
│   ├── base/               Shared manifests (all environments)           │
│   │   ├── namespace.yaml                                                 │
│   │   ├── configmap.yaml   Environment variables                        │
│   │   ├── secrets.yaml     Sensitive data (base64)                      │
│   │   ├── postgres.yaml    Database deployment                          │
│   │   ├── redis.yaml       Queue/cache deployment                       │
│   │   ├── elasticsearch.yaml  Search/analytics                          │
│   │   ├── api.yaml         API service (Deployment + Service)           │
│   │   └── worker.yaml      Worker service (Deployment)                  │
│   │                                                                      │
│   ├── overlays/           Environment-specific patches                  │
│   │   ├── dev/            1 replica, debug logging                      │
│   │   ├── staging/        2 replicas, info logging                      │
│   │   └── prod/           5+ replicas, HPA, production config           │
│   │                                                                      │
│   └── advanced/           Production hardening                          │
│       ├── hpa.yaml         Horizontal Pod Autoscaler                    │
│       ├── rbac.yaml        RBAC & Network Policies                      │
│       ├── alerts.yaml      Prometheus alerting rules                    │
│       └── api-rollout.yaml Argo Rollouts (Blue/Green)                   │
│                                                                          │
│   Deployment Options:                                                    │
│   ├── kubectl apply -k overlays/dev                                      │
│   └── ArgoCD syncs from overlays/ (GitOps)                              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
k8s/
├── base/                    # Base manifests (shared across environments)
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secrets.yaml
│   ├── postgres.yaml
│   ├── redis.yaml
│   ├── elasticsearch.yaml
│   ├── api.yaml
│   └── worker.yaml
│
├── overlays/                # Environment-specific overrides
│   ├── dev/                 # Development (1 replica, debug logging)
│   ├── staging/             # Staging (2 replicas, info logging)
│   └── prod/                # Production (5+ replicas, HPA enabled)
│
└── advanced/                # Advanced configurations
    ├── hpa.yaml             # Horizontal Pod Autoscaler
    ├── rbac.yaml            # RBAC & Network Policies
    ├── alerts.yaml          # Prometheus alerting rules
    └── api-rollout.yaml     # Blue/Green rollout (Argo Rollouts)
```

## How Kustomize Works

```
base/kustomization.yaml          overlays/prod/kustomization.yaml
        │                                  │
        │                                  │ patches:
        │                                  │   - replicas: 5
        │                                  │   - resources: increased
        │                                  │   - LOG_LEVEL: warn
        ▼                                  ▼
┌─────────────────┐            ┌─────────────────┐
│  Base Manifests │  ────────► │ Patched Output  │
│  (1 replica)    │  kustomize │ (5 replicas)    │
│  (debug logs)   │   build    │ (warn logs)     │
└─────────────────┘            └─────────────────┘
```

## Quick Start

```bash
# Development
kubectl apply -k overlays/dev

# Staging
kubectl apply -k overlays/staging

# Production
kubectl apply -k overlays/prod

# Preview rendered manifests
kubectl kustomize overlays/prod
```

## Environment Comparison

| Environment | API Replicas | Worker Replicas | Log Level | HPA | Resources |
|-------------|--------------|-----------------|-----------|-----|-----------|
| Dev         | 1            | 1               | debug     | No  | Minimal   |
| Staging     | 2            | 2               | info      | No  | Medium    |
| Prod        | 5+           | 3+              | warn      | Yes | High      |

## Base Manifests

### ConfigMap (`base/configmap.yaml`)
Environment variables for all services:
- `DATABASE_URL` - PostgreSQL connection
- `REDIS_URL` - Redis connection
- `ELASTICSEARCH_URL` - Elasticsearch connection
- `LOG_LEVEL` - Logging verbosity

### Secrets (`base/secrets.yaml`)
Sensitive data (base64 encoded):
- `DB_PASSWORD` - Database password
- `REDIS_PASSWORD` - Redis password
- `API_SECRET` - JWT signing key

### Deployments
- `api.yaml` - REST API with health probes
- `worker.yaml` - Queue processor with graceful shutdown
- `postgres.yaml` - Database with persistent volume
- `redis.yaml` - Queue and cache
- `elasticsearch.yaml` - Search and analytics

## Advanced Configurations

### HPA (`advanced/hpa.yaml`)
```yaml
# Scales API pods based on CPU/memory
minReplicas: 3
maxReplicas: 10
targetCPUUtilization: 70%
```

### KEDA (`advanced/keda-scaledobject.yaml`)
```yaml
# Scales workers based on Redis queue depth
triggers:
  - type: redis
    listLength: "50"
```

### Argo Rollouts (`advanced/api-rollout.yaml`)
```yaml
# Blue/Green deployment strategy
strategy:
  blueGreen:
    activeService: api-active
    previewService: api-preview
```

## Kustomize vs Helm

| Feature | Kustomize | Helm |
|---------|-----------|------|
| Complexity | Simple patches | Full templating |
| Learning curve | Low | Medium |
| Reusability | Environment overlays | Packaged charts |
| Best for | Internal deployments | Distribution |

This repository supports both - see [../charts/](../charts/) for Helm charts.

## Related Resources

| Resource | Location |
|----------|----------|
| Helm Charts | [../charts/](../charts/) |
| ArgoCD Apps | [../argocd/](../argocd/) |
| Terraform | [../terraform/](../terraform/) |
| Article Reference | [Part 6: Kubernetes Fundamentals](../../articles/06-kubernetes-fundamentals.md) |
| Production  | 5+           | 10+             | info      | Yes |

## Advanced Features

```bash
# Enable HPA
kubectl apply -f advanced/hpa.yaml -n sspp-prod

# Enable Network Policies
kubectl apply -f advanced/rbac.yaml -n sspp-prod

# Enable Prometheus Alerts
kubectl apply -f advanced/alerts.yaml -n sspp-prod

# Blue/Green Deployments (requires Argo Rollouts)
kubectl apply -f advanced/api-rollout.yaml -n sspp-prod
```
