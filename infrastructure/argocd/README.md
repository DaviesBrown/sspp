# ArgoCD Applications

This directory contains ArgoCD Application manifests for GitOps deployment.

## Structure

- `root-app.yaml` - App of Apps pattern, manages all other applications
- `dev-app.yaml` - Development environment application
- `staging-app.yaml` - Staging environment application
- `prod-app.yaml` - Production environment application
- `sspp-prod-app.yaml` - Alternative production app manifest
- `notifications-cm.yaml` - Slack notification configuration
- `rbac-cm.yaml` - RBAC permissions configuration

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

## Prerequisites

- ArgoCD installed in the cluster
- Repository access configured in ArgoCD
- Kubernetes namespaces created (or enable CreateNamespace sync option)
