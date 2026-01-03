# ArgoCD Applications

This directory contains ArgoCD Application manifests for GitOps deployment of the Sales Signal Processing Platform.

## How ArgoCD Fits the Project

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         GitOps Workflow                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Developer                                                              │
│       │                                                                  │
│       │ 1. Push code to GitHub                                          │
│       ▼                                                                  │
│   ┌─────────────────┐                                                   │
│   │  GitHub Actions │  2. Build & push Docker image                     │
│   └────────┬────────┘                                                   │
│            │                                                             │
│            │ 3. Update image tag in k8s/overlays/                       │
│            ▼                                                             │
│   ┌─────────────────┐                                                   │
│   │    ArgoCD       │  ◄── YOU ARE HERE                                 │
│   │  (watches repo) │                                                   │
│   └────────┬────────┘                                                   │
│            │                                                             │
│            │ 4. Detect drift, sync manifests                            │
│            ▼                                                             │
│   ┌─────────────────┐                                                   │
│   │   Kubernetes    │  5. Deploy updated pods                           │
│   │    Cluster      │                                                   │
│   └─────────────────┘                                                   │
│                                                                          │
│   Sources:                                                               │
│   ├── argocd/*.yaml     (Application definitions)                       │
│   ├── k8s/overlays/*    (Environment-specific manifests)                │
│   └── charts/*          (Helm charts for templating)                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
argocd/
├── root-app.yaml          # App of Apps pattern (manages all below)
├── dev-app.yaml           # Development environment
├── staging-app.yaml       # Staging environment
├── prod-app.yaml          # Production environment
├── sspp-prod-app.yaml     # Alternative production manifest
├── notifications-cm.yaml  # Slack notification configuration
└── rbac-cm.yaml           # RBAC permissions configuration
```

## App of Apps Pattern

The `root-app.yaml` implements the **App of Apps** pattern:

```
root-app.yaml
     │
     ├──► dev-app.yaml     ──► k8s/overlays/dev/
     │
     ├──► staging-app.yaml ──► k8s/overlays/staging/
     │
     └──► prod-app.yaml    ──► k8s/overlays/prod/
```

This pattern enables:
- **Single deployment** - One `kubectl apply` deploys everything
- **Environment isolation** - Each app targets a different namespace
- **Declarative management** - ArgoCD self-manages applications

## Usage

### Initial Setup

Apply the root app first:

```bash
kubectl apply -f root-app.yaml
```

This will automatically manage all child applications via GitOps.

### Individual Deployments

Or deploy environments individually:

```bash
kubectl apply -f dev-app.yaml
kubectl apply -f staging-app.yaml
kubectl apply -f prod-app.yaml
```

### Check Sync Status

```bash
# Via CLI
argocd app list
argocd app get sspp-prod

# Via UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Visit https://localhost:8080
```

## Application Targets

| Application | Target Path | Namespace |
|-------------|-------------|-----------|
| `sspp-dev` | `infrastructure/k8s/overlays/dev` | `sspp-dev` |
| `sspp-staging` | `infrastructure/k8s/overlays/staging` | `sspp-staging` |
| `sspp-prod` | `infrastructure/k8s/overlays/prod` | `sspp-prod` |

## Prerequisites

- ArgoCD installed in the cluster (`../scripts/install-tools.sh 1`)
- Repository access configured in ArgoCD
- Kubernetes namespaces created (or enable CreateNamespace sync option)

## Notifications

The `notifications-cm.yaml` configures Slack notifications for:
- Sync started
- Sync succeeded
- Sync failed
- Health degraded

## Related Resources

| Resource | Location |
|----------|----------|
| Kubernetes Manifests | [../k8s/](../k8s/) |
| Helm Charts | [../charts/](../charts/) |
| Install ArgoCD | [../scripts/install-tools.sh](../scripts/install-tools.sh) |
| Article Reference | [Part 9: ArgoCD & GitOps](../../articles/09-argocd-gitops.md) |
