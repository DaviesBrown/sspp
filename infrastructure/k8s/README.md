# Kubernetes Manifests

Kubernetes manifests for deploying SSPP using Kustomize.

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

## Quick Start

```bash
# Development
kubectl apply -k overlays/dev

# Staging
kubectl apply -k overlays/staging

# Production
kubectl apply -k overlays/prod
```

## Environment Comparison

| Environment | API Replicas | Worker Replicas | Log Level | HPA |
|-------------|--------------|-----------------|-----------|-----|
| Dev         | 1            | 1               | debug     | No  |
| Staging     | 2            | 2               | info      | No  |
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
