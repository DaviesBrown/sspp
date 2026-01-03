#!/bin/bash
# Check health of all infrastructure tools
set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║             Infrastructure Health Check                    ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_namespace() {
    local ns=$1
    local name=$2
    
    if kubectl get namespace $ns &>/dev/null; then
        ready=$(kubectl get pods -n $ns --no-headers 2>/dev/null | grep -c "Running" || echo 0)
        total=$(kubectl get pods -n $ns --no-headers 2>/dev/null | wc -l || echo 0)
        
        if [ "$ready" -eq "$total" ] && [ "$total" -gt 0 ]; then
            echo -e "${GREEN}✓${NC} $name: $ready/$total pods running"
        elif [ "$total" -eq 0 ]; then
            echo -e "${YELLOW}○${NC} $name: No pods found"
        else
            echo -e "${RED}✗${NC} $name: $ready/$total pods running"
        fi
    else
        echo -e "${YELLOW}○${NC} $name: Not installed"
    fi
}

echo "Kubernetes Tools:"
echo "─────────────────"
check_namespace "argocd" "ArgoCD"
check_namespace "monitoring" "Prometheus/Grafana"
check_namespace "logging" "Loki"
check_namespace "argo-rollouts" "Argo Rollouts"
check_namespace "keda" "KEDA"

echo ""
echo "Application Namespaces:"
echo "───────────────────────"
check_namespace "sspp-dev" "SSPP Dev"
check_namespace "sspp-staging" "SSPP Staging"
check_namespace "sspp-prod" "SSPP Production"

echo ""
echo "Services:"
echo "─────────"
for ns in argocd monitoring; do
    if kubectl get namespace $ns &>/dev/null; then
        echo "$ns:"
        kubectl get svc -n $ns --no-headers 2>/dev/null | awk '{print "  - " $1 ": " $4}'
    fi
done
