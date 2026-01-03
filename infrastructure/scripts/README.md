# Infrastructure Scripts

Scripts for installing and managing infrastructure tools on the SSPP Kubernetes cluster.

## How Scripts Fit the Project

```
┌─────────────────────────────────────────────────────────────────────────┐
│                   Infrastructure Setup Flow                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1. Provision Cluster                                                    │
│     terraform/  ────────►  Linode LKE Cluster (nodes ready)             │
│                                   │                                      │
│                                   ▼                                      │
│  2. Install Platform Tools                                               │
│     scripts/              ◄── YOU ARE HERE                              │
│     install-tools.sh  ────►  Install:                                   │
│                              ├── ArgoCD (GitOps)                        │
│                              ├── Prometheus + Grafana (Monitoring)      │
│                              ├── Loki (Logging)                         │
│                              ├── Argo Rollouts (Progressive Delivery)   │
│                              └── KEDA (Event-driven Scaling)            │
│                                   │                                      │
│                                   ▼                                      │
│  3. Deploy Application                                                   │
│     argocd/  ──────────────►  GitOps deployment of SSPP services       │
│                                   │                                      │
│                                   ▼                                      │
│  4. Monitor & Operate                                                    │
│     port-forward-dashboards.sh  ──►  Access Grafana, ArgoCD UI         │
│     check-health.sh  ────────────►  Verify all components running      │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Available Scripts

| Script | Purpose |
|--------|---------|
| `install-tools.sh` | Install all platform tools via Helm |
| `port-forward-dashboards.sh` | Open local access to dashboards |
| `check-health.sh` | Verify all infrastructure components |

## Quick Install

```bash
# Install all tools (recommended for new clusters)
./install-tools.sh 6

# Or run interactively to select specific tools
./install-tools.sh
```

## Tools Installed

| Tool | Purpose | Namespace | Dashboard Port |
|------|---------|-----------|----------------|
| ArgoCD | GitOps continuous delivery | `argocd` | 8080 |
| Prometheus | Metrics collection | `monitoring` | 9090 |
| Grafana | Dashboards & visualization | `monitoring` | 3000 |
| Loki | Log aggregation | `logging` | 3100 |
| Argo Rollouts | Blue/Green, Canary deployments | `argo-rollouts` | 3100 |
| KEDA | Event-driven autoscaling | `keda` | N/A |

## Individual Installation

```bash
./install-tools.sh 1  # ArgoCD only
./install-tools.sh 2  # Prometheus + Grafana
./install-tools.sh 3  # Loki
./install-tools.sh 4  # Argo Rollouts
./install-tools.sh 5  # KEDA
./install-tools.sh 6  # All of the above
```

## Access Dashboards

```bash
# Start all port-forwards (runs in foreground)
./port-forward-dashboards.sh

# Or manually:
# ArgoCD (admin / get password below)
kubectl port-forward svc/argocd-server 8080:443 -n argocd

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d

# Grafana (admin / prom-operator)
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring

# Prometheus
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring

# Argo Rollouts Dashboard
kubectl port-forward svc/argo-rollouts-dashboard 3100:3100 -n argo-rollouts
```

## Verify Installation

```bash
# Run health check
./check-health.sh

# Manual verification
kubectl get pods -n argocd
kubectl get pods -n monitoring
kubectl get pods -n logging
kubectl get pods -n argo-rollouts
kubectl get pods -n keda
```

## Helm Repositories Used

The `install-tools.sh` script adds these Helm repositories:

| Repository | URL |
|------------|-----|
| argo | `https://argoproj.github.io/argo-helm` |
| prometheus-community | `https://prometheus-community.github.io/helm-charts` |
| grafana | `https://grafana.github.io/helm-charts` |
| kedacore | `https://kedacore.github.io/charts` |

## Customization

To customize tool configuration, edit the Helm values in `install-tools.sh` or create separate values files:

```bash
# Example: Custom Prometheus settings
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f custom-prometheus-values.yaml
```

## Troubleshooting

### ArgoCD not starting
```bash
kubectl describe pod -n argocd -l app.kubernetes.io/name=argocd-server
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

### Prometheus no data
```bash
# Check Prometheus targets
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring
# Visit http://localhost:9090/targets
```

### Loki not receiving logs
```bash
# Check Promtail (log shipper) pods
kubectl logs -n logging -l app.kubernetes.io/name=promtail
```

## Related Resources

| Resource | Location |
|----------|----------|
| ArgoCD Apps | [../argocd/](../argocd/) |
| Kubernetes Manifests | [../k8s/](../k8s/) |
| Terraform | [../terraform/](../terraform/) |
| Alerts Configuration | [../k8s/advanced/alerts.yaml](../k8s/advanced/alerts.yaml) |
| Article Reference | [Part 10: Production Operations](../../articles/10-scaling-failure-production-operations.md) |

```bash
# Check all pods
kubectl get pods -n argocd
kubectl get pods -n monitoring
kubectl get pods -n logging
kubectl get pods -n argo-rollouts
kubectl get pods -n keda
```

## Uninstall

```bash
helm uninstall argocd -n argocd
helm uninstall prometheus -n monitoring
helm uninstall loki -n logging
helm uninstall argo-rollouts -n argo-rollouts
helm uninstall keda -n keda
```
