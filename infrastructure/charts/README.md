# Helm Charts

Helm charts for packaging SSPP services.

```
charts/
├── api/             # API service chart
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-dev.yaml
│   ├── values-prod.yaml
│   └── templates/
│
└── worker/          # Worker service chart
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
```

## Usage

```bash
# Install API (dev)
helm install sspp-api ./api -f ./api/values-dev.yaml

# Install API (prod)
helm install sspp-api ./api -f ./api/values-prod.yaml -n production

# Upgrade
helm upgrade sspp-api ./api --set image.tag=v1.2.3

# Rollback
helm rollback sspp-api
```
