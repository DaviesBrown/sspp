# Infrastructure

All infrastructure configuration for the Sales Signal Processing Platform (SSPP).

## How Infrastructure Fits the Project

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     SSPP Repository Structure                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   📁 services/                                                           │
│   │   ├── api/           Application code (NestJS)                      │
│   │   └── worker/        Processing code (Node.js)                      │
│   │                                                                      │
│   │         │                                                            │
│   │         │ Built into Docker images                                   │
│   │         ▼                                                            │
│   │                                                                      │
│   📁 infrastructure/     ◄── YOU ARE HERE                               │
│   │   │                                                                  │
│   │   ├── terraform/     Provisions cloud resources (Linode LKE)        │
│   │   │       │                                                          │
│   │   │       ▼                                                          │
│   │   ├── k8s/           Kubernetes manifests (Kustomize)               │
│   │   │       │                                                          │
│   │   │       ▼                                                          │
│   │   ├── charts/        Helm charts for templating                     │
│   │   │       │                                                          │
│   │   │       ▼                                                          │
│   │   ├── argocd/        GitOps deployment definitions                  │
│   │   │       │                                                          │
│   │   │       ▼                                                          │
│   │   ├── database/      SQL schemas and migrations                     │
│   │   │                                                                  │
│   │   └── scripts/       Tool installation & utilities                  │
│   │                                                                      │
│   📁 .github/workflows/  CI/CD pipelines                                │
│   📁 articles/           Documentation (explains all of this)           │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
infrastructure/
├── argocd/          # ArgoCD GitOps applications
├── charts/          # Helm charts (API, Worker)
├── database/        # SQL init/seed scripts
├── k8s/             # Kubernetes manifests (Kustomize)
├── scripts/         # Tool installation scripts
└── terraform/       # Infrastructure as Code (Linode)
```

## The Infrastructure Pipeline

```
┌────────────────────────────────────────────────────────────────────────┐
│                    Deployment Pipeline                                  │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1. PROVISION CLUSTER                                                   │
│     terraform/  ──────────►  Linode LKE Cluster                        │
│                              (NodeBalancer, Firewall, DNS)              │
│                                                                         │
│  2. INSTALL TOOLS                                                       │
│     scripts/install-tools.sh  ──►  ArgoCD, Prometheus, Loki, KEDA      │
│                                                                         │
│  3. DEPLOY APPLICATION                                                  │
│     Option A: kubectl apply -k k8s/overlays/prod                       │
│     Option B: ArgoCD syncs from argocd/root-app.yaml (GitOps)          │
│                                                                         │
│  4. HELM PACKAGING                                                      │
│     charts/  ──────────────►  Templated manifests with values          │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Provision Cloud Infrastructure
```bash
cd terraform/environments/prod
terraform init && terraform apply
```

### 2. Install Platform Tools
```bash
./scripts/install-tools.sh 6  # Install all (ArgoCD, Prometheus, etc.)
```

### 3. Deploy Application
```bash
kubectl apply -k k8s/overlays/prod
# Or use ArgoCD (recommended for production):
kubectl apply -f argocd/root-app.yaml
```

### 4. Access Dashboards
```bash
./scripts/port-forward-dashboards.sh
```

## Directory Details

| Directory | Purpose | Article Reference |
|-----------|---------|-------------------|
| `terraform/` | Linode infrastructure (LKE, storage, DNS) | [Part 7: Terraform IaC](../articles/07-terraform-infrastructure-as-code.md) |
| `k8s/` | Kubernetes manifests with Kustomize overlays | [Part 6: Kubernetes](../articles/06-kubernetes-fundamentals.md) |
| `charts/` | Helm charts for API and Worker | [Part 8: Helm Charts](../articles/08-helm-packaging-kubernetes-apps.md) |
| `argocd/` | GitOps application manifests | [Part 9: ArgoCD & GitOps](../articles/09-argocd-gitops.md) |
| `database/` | PostgreSQL init and seed SQL | [Part 6: Kubernetes](../articles/06-kubernetes-fundamentals.md) |
| `scripts/` | Installation and helper scripts | [Part 10: Production Ops](../articles/10-scaling-failure-production-operations.md) |

## Environment Strategy

| Environment | Namespace | Replicas | Purpose |
|-------------|-----------|----------|---------|
| Development | `sspp-dev` | 1 | Local testing, debugging |
| Staging | `sspp-staging` | 2 | Pre-production validation |
| Production | `sspp-prod` | 5+ | Live traffic, HPA enabled |

## Related Resources

| Resource | Location |
|----------|----------|
| Application Services | [services/](../services/) |
| CI/CD Workflows | [.github/workflows/](../.github/workflows/) |
| Docker Compose | [docker-compose.yml](../docker-compose.yml) |
| Article Series | [articles/](../articles/) |
| Project PRD | [prd-project-description.md](../prd-project-description.md) |
