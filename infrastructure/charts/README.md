# Helm Charts

Helm charts for packaging SSPP services as reusable, templated Kubernetes applications.

## How Helm Charts Fit the Project

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Helm in the Deployment Pipeline                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   services/                                                              │
│   ├── api/Dockerfile      ──►  Docker Image                             │
│   └── worker/Dockerfile   ──►  Docker Image                             │
│                                    │                                     │
│                                    ▼                                     │
│                                                                          │
│   charts/                 ◄── YOU ARE HERE                              │
│   ├── api/                                                               │
│   │   ├── Chart.yaml           Chart metadata                           │
│   │   ├── values.yaml          Default values                           │
│   │   ├── values-dev.yaml      Dev overrides (1 replica)                │
│   │   ├── values-prod.yaml     Prod overrides (5+ replicas)             │
│   │   └── templates/           K8s manifests with {{ .Values }}         │
│   │                                                                      │
│   └── worker/                                                            │
│       └── ...                                                            │
│                                    │                                     │
│                                    ▼                                     │
│                                                                          │
│   Options:                                                               │
│   ├── helm install directly                                              │
│   ├── ArgoCD (references charts or rendered manifests)                  │
│   └── k8s/overlays/ (Kustomize, alternative approach)                   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
charts/
├── api/                 # API service chart
│   ├── Chart.yaml       # Chart metadata and version
│   ├── values.yaml      # Default configuration values
│   ├── values-dev.yaml  # Development overrides
│   ├── values-prod.yaml # Production overrides
│   └── templates/       # Kubernetes manifest templates
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       ├── configmap.yaml
│       └── hpa.yaml
│
└── worker/              # Worker service chart
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
        ├── deployment.yaml
        ├── service.yaml
        └── configmap.yaml
```

## Helm vs Kustomize

This repository supports **both** approaches:

| Approach | Location | Best For |
|----------|----------|----------|
| **Helm Charts** | `charts/` | Packaging for distribution, complex templating |
| **Kustomize** | `k8s/overlays/` | Environment-specific patches, simpler config |

ArgoCD can deploy using either approach.

## Usage

### Install API Service

```bash
# Development
helm install sspp-api ./api -f ./api/values-dev.yaml -n sspp-dev

# Production
helm install sspp-api ./api -f ./api/values-prod.yaml -n sspp-prod
```

### Install Worker Service

```bash
# Development
helm install sspp-worker ./worker -n sspp-dev

# Production
helm install sspp-worker ./worker --set replicaCount=5 -n sspp-prod
```

### Upgrade with New Image

```bash
helm upgrade sspp-api ./api --set image.tag=v1.2.3 -n sspp-prod
```

### Rollback

```bash
helm rollback sspp-api -n sspp-prod
```

### Template Preview

```bash
# See rendered manifests without applying
helm template sspp-api ./api -f ./api/values-prod.yaml
```

## Values Overview

### API Chart (`api/values.yaml`)

| Value | Description | Default |
|-------|-------------|---------|
| `replicaCount` | Number of pods | `2` |
| `image.repository` | Docker image | `your-registry/sspp-api` |
| `image.tag` | Image version | `latest` |
| `service.port` | Service port | `3000` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `hpa.enabled` | Enable autoscaling | `false` |

### Worker Chart (`worker/values.yaml`)

| Value | Description | Default |
|-------|-------------|---------|
| `replicaCount` | Number of pods | `1` |
| `image.repository` | Docker image | `your-registry/sspp-worker` |
| `concurrency` | Jobs per worker | `5` |
| `keda.enabled` | KEDA scaling | `false` |

## Related Resources

| Resource | Location |
|----------|----------|
| Kubernetes Manifests | [../k8s/](../k8s/) |
| ArgoCD Apps | [../argocd/](../argocd/) |
| API Service Code | [../../services/api/](../../services/api/) |
| Worker Service Code | [../../services/worker/](../../services/worker/) |
| Article Reference | [Part 8: Helm Charts](../../articles/08-helm-packaging-kubernetes-apps.md) |
