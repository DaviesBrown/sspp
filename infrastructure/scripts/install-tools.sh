#!/bin/bash
# SSPP Infrastructure Tools Installation Script
# Installs: ArgoCD, Prometheus, Grafana, Loki, Argo Rollouts, KEDA
set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          SSPP Infrastructure Tools Installer              ║"
echo "╚═══════════════════════════════════════════════════════════╝"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 is required but not installed."
        exit 1
    fi
}

# Check prerequisites
log_info "Checking prerequisites..."
check_command kubectl
check_command helm

# Get current context
CONTEXT=$(kubectl config current-context)
log_info "Using Kubernetes context: $CONTEXT"
read -p "Continue with this context? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Add Helm repositories
log_info "Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add argo https://argoproj.github.io/argo-helm
helm repo add kedacore https://kedacore.github.io/charts
helm repo update

# ============================================================
# 1. ArgoCD (GitOps)
# ============================================================
install_argocd() {
    log_info "Installing ArgoCD..."
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    
    helm upgrade --install argocd argo/argo-cd \
        --namespace argocd \
        --set server.service.type=LoadBalancer \
        --set configs.params."server\.insecure"=true \
        --wait
    
    log_info "ArgoCD installed!"
    log_info "Get initial admin password:"
    echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

# ============================================================
# 2. Prometheus Stack (Metrics + Alertmanager + Grafana)
# ============================================================
install_prometheus_stack() {
    log_info "Installing Prometheus Stack (includes Grafana)..."
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --set grafana.adminPassword=admin \
        --set grafana.service.type=LoadBalancer \
        --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
        --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
        --wait
    
    log_info "Prometheus Stack installed!"
    log_info "Access Grafana: kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring"
    log_info "Default credentials: admin / admin"
}

# ============================================================
# 3. Loki Stack (Log Aggregation)
# ============================================================
install_loki() {
    log_info "Installing Loki (Log Aggregation)..."
    kubectl create namespace logging --dry-run=client -o yaml | kubectl apply -f -
    
    helm upgrade --install loki grafana/loki-stack \
        --namespace logging \
        --set promtail.enabled=true \
        --set grafana.enabled=false \
        --wait
    
    log_info "Loki installed!"
    log_info "Add Loki as datasource in Grafana: http://loki.logging:3100"
}

# ============================================================
# 4. Argo Rollouts (Progressive Delivery)
# ============================================================
install_argo_rollouts() {
    log_info "Installing Argo Rollouts..."
    kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f -
    
    helm upgrade --install argo-rollouts argo/argo-rollouts \
        --namespace argo-rollouts \
        --set dashboard.enabled=true \
        --set dashboard.service.type=LoadBalancer \
        --wait
    
    log_info "Argo Rollouts installed!"
    log_info "Access dashboard: kubectl port-forward svc/argo-rollouts-dashboard 3100:3100 -n argo-rollouts"
}

# ============================================================
# 5. KEDA (Event-Driven Autoscaling)
# ============================================================
install_keda() {
    log_info "Installing KEDA..."
    kubectl create namespace keda --dry-run=client -o yaml | kubectl apply -f -
    
    helm upgrade --install keda kedacore/keda \
        --namespace keda \
        --wait
    
    log_info "KEDA installed!"
}

# ============================================================
# Menu
# ============================================================
show_menu() {
    echo ""
    echo "Select tools to install:"
    echo "  1) ArgoCD (GitOps)"
    echo "  2) Prometheus + Grafana (Monitoring)"
    echo "  3) Loki (Logging)"
    echo "  4) Argo Rollouts (Blue/Green, Canary)"
    echo "  5) KEDA (Event-Driven Autoscaling)"
    echo "  6) ALL (Recommended for production)"
    echo "  0) Exit"
    echo ""
}

install_all() {
    install_argocd
    install_prometheus_stack
    install_loki
    install_argo_rollouts
    install_keda
    
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║              All tools installed successfully!            ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    echo "Access URLs (use kubectl port-forward or LoadBalancer IPs):"
    echo "  - ArgoCD:        kubectl port-forward svc/argocd-server 8080:443 -n argocd"
    echo "  - Grafana:       kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring"
    echo "  - Argo Rollouts: kubectl port-forward svc/argo-rollouts-dashboard 3100:3100 -n argo-rollouts"
    echo ""
}

# Main
if [[ $# -eq 0 ]]; then
    show_menu
    read -p "Enter choice [0-6]: " choice
else
    choice=$1
fi

case $choice in
    1) install_argocd ;;
    2) install_prometheus_stack ;;
    3) install_loki ;;
    4) install_argo_rollouts ;;
    5) install_keda ;;
    6) install_all ;;
    0) exit 0 ;;
    *) log_error "Invalid choice"; exit 1 ;;
esac
