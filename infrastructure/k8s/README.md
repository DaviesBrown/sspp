# Kubernetes Manifests

This directory contains Kubernetes manifests for deploying the Sales Signal Processing Platform.

## Quick Start

```bash
# Apply all manifests
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secrets.yaml
kubectl apply -f postgres.yaml
kubectl apply -f redis.yaml
kubectl apply -f elasticsearch.yaml
kubectl apply -f api.yaml
kubectl apply -f worker.yaml
```

Or apply everything at once:
```bash
kubectl apply -f .
```

## Components

### Infrastructure
- **namespace.yaml**: Creates dev and prod namespaces
- **configmap.yaml**: Configuration values
- **secrets.yaml**: Sensitive configuration (passwords, tokens)

### Data Layer
- **postgres.yaml**: PostgreSQL database with PVC
- **redis.yaml**: Redis queue/cache with PVC
- **elasticsearch.yaml**: Elasticsearch with PVC

### Application Layer
- **api.yaml**: API service with LoadBalancer and HPA
- **worker.yaml**: Worker deployment with HPA

## Resource Requests

| Component      | CPU Request | Memory Request | Storage |
|----------------|-------------|----------------|---------|
| PostgreSQL     | 250m        | 512Mi          | 10Gi    |
| Redis          | 100m        | 256Mi          | 5Gi     |
| Elasticsearch  | 500m        | 1Gi            | 20Gi    |
| API (per pod)  | 200m        | 256Mi          | -       |
| Worker (per pod)| 200m       | 256Mi          | -       |

## Autoscaling

- **API**: 2-10 replicas (CPU: 70%, Memory: 80%)
- **Worker**: 3-15 replicas (CPU: 70%, Memory: 80%)

## Accessing Services

### Get API LoadBalancer IP
```bash
kubectl get svc api-service -n sspp-dev
```

### Port Forward for Development
```bash
# API
kubectl port-forward -n sspp-dev svc/api-service 3000:80

# PostgreSQL
kubectl port-forward -n sspp-dev svc/postgres-service 5432:5432

# Redis
kubectl port-forward -n sspp-dev svc/redis-service 6379:6379

# Elasticsearch
kubectl port-forward -n sspp-dev svc/elasticsearch-service 9200:9200
```

## Monitoring

### Check Pod Status
```bash
kubectl get pods -n sspp-dev
```

### View Logs
```bash
# API logs
kubectl logs -n sspp-dev -l app=api -f

# Worker logs
kubectl logs -n sspp-dev -l app=worker -f
```

### Describe Resources
```bash
kubectl describe deployment api -n sspp-dev
kubectl describe hpa api-hpa -n sspp-dev
```

## Updating Deployments

### Update Image
```bash
kubectl set image deployment/api -n sspp-dev api=sspp/api:v1.2.0
```

### Rolling Update Status
```bash
kubectl rollout status deployment/api -n sspp-dev
```

### Rollback
```bash
kubectl rollout undo deployment/api -n sspp-dev
```

## Security Notes

- **Production**: Replace secrets.yaml with sealed secrets or external secret management
- **RBAC**: Implement proper role-based access control
- **Network Policies**: Add network policies to restrict pod communication
- **Pod Security**: Enable Pod Security Standards

## Cleanup

```bash
kubectl delete namespace sspp-dev
# or
kubectl delete -f .
```
