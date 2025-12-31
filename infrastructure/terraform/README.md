# Terraform Infrastructure

This directory contains Infrastructure as Code (IaC) definitions for the Sales Signal Processing Platform.

## Prerequisites

- Terraform >= 1.0
- Linode account and API token
- kubectl installed

## Getting Started

1. **Set up credentials**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars and add your Linode API token
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Plan infrastructure**:
   ```bash
   terraform plan
   ```

4. **Apply infrastructure**:
   ```bash
   terraform apply
   ```

5. **Get kubeconfig**:
   ```bash
   terraform output -raw kubeconfig > ~/.kube/sspp-config
   export KUBECONFIG=~/.kube/sspp-config
   kubectl get nodes
   ```

## Resources Created

- **Kubernetes Cluster (LKE)**: 3-node cluster with autoscaling
- **PostgreSQL Database**: Managed PostgreSQL instance
- **Object Storage**: Backup storage bucket
- **Firewall**: Security rules for cluster

## Cost Estimates

Development environment (~$150/month):
- 3x g6-standard-2 nodes: ~$90/month
- PostgreSQL g6-nanode-1: ~$15/month
- Object Storage: ~$5/month
- Networking: ~$10/month

## Environments

- **dev**: Development environment (smaller resources)
- **staging**: Staging environment (production-like)
- **prod**: Production environment (full resources)

## Maintenance

### Scaling the cluster
```bash
terraform apply -var="node_count=5"
```

### Destroying infrastructure
```bash
terraform destroy
```

## Security

- Never commit `terraform.tfvars` or state files
- Use separate state backends for production
- Enable remote state with encryption
- Rotate API tokens regularly
