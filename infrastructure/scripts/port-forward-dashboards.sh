#!/bin/bash
# Quick access to all dashboards via port-forward
set -e

echo "Starting port-forwards for all dashboards..."
echo "Press Ctrl+C to stop all"
echo ""

# Kill existing port-forwards
pkill -f "kubectl port-forward" 2>/dev/null || true

# Start port-forwards in background
kubectl port-forward svc/argocd-server 8080:443 -n argocd &
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring &
kubectl port-forward svc/argo-rollouts-dashboard 3100:3100 -n argo-rollouts &
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring &

echo "╔════════════════════════════════════════════╗"
echo "║           Dashboard URLs                   ║"
echo "╠════════════════════════════════════════════╣"
echo "║  ArgoCD:        http://localhost:8080      ║"
echo "║  Grafana:       http://localhost:3000      ║"
echo "║  Prometheus:    http://localhost:9090      ║"
echo "║  Argo Rollouts: http://localhost:3100      ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "ArgoCD password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || echo "(not found)"
echo ""
echo ""
echo "Grafana: admin / admin"
echo ""

# Wait for interrupt
wait
