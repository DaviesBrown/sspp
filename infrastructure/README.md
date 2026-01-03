# Infrastructure

All infrastructure configuration for SSPP.

```
infrastructure/
├── argocd/          # ArgoCD GitOps applications
├── charts/          # Helm charts (API, Worker)
├── database/        # SQL init/seed scripts
├── k8s/             # Kubernetes manifests (Kustomize)
├── scripts/         # Tool installation scripts
└── terraform/       # Infrastructure as Code (Linode)
```

## Quick Start

### 1. Install Tools
```bash
./scripts/install-tools.sh 6  # Install all (ArgoCD, Prometheus, etc.)
```

### 2. Deploy Infrastructure
```bash
cd terraform/environments/prod
terraform init && terraform apply
```

### 3. Deploy Application
```bash
kubectl apply -k k8s/overlays/prod
# Or use ArgoCD:
kubectl apply -f argocd/root-app.yaml
```

### 4. Access Dashboards
```bash
./scripts/port-forward-dashboards.sh
```

## Directory Details

| Directory | Purpose |
|-----------|---------|
| `argocd/` | GitOps application manifests |
| `charts/` | Helm charts for API and Worker |
| `database/` | PostgreSQL init and seed SQL |
| `k8s/` | Kubernetes manifests with Kustomize overlays |
| `scripts/` | Installation and helper scripts |
| `terraform/` | Linode infrastructure (LKE, storage, DNS) |
