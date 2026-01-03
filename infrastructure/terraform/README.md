# Terraform Infrastructure

Infrastructure as Code for provisioning SSPP cloud resources on Linode.

## Simplified Structure

```
terraform/
├── main.tf              # All resources + backend config
├── variables.tf         # Input variables
├── terraform.tfvars.example
│
├── environments/        # Environment-specific tfvars
│   ├── dev/
│   └── prod/
│
└── modules/             # Reusable modules (optional)
    └── lke-cluster/
```

**Why so few files?** Terraform doesn't require separate files - it merges all `.tf` files in a directory. For a project this size, one `main.tf` is cleaner and easier to understand.

## Backend Options

The backend (where state is stored) is configured in `main.tf`. Choose ONE:

### Option 1: Terraform Cloud (Recommended)

Free tier includes state management, locking, and secret storage:

```hcl
terraform {
  cloud {
    organization = "your-org"
    workspaces {
      name = "sspp-prod"
    }
  }
}
```

Benefits:
- ✅ Free state storage with versioning
- ✅ Built-in state locking
- ✅ Secrets stored securely (no tfvars files)
- ✅ Run history and audit logs
- ✅ Team collaboration features

### Option 2: S3-Compatible (Linode Object Storage)

```hcl
terraform {
  backend "s3" {
    bucket   = "sspp-terraform-state"
    key      = "terraform.tfstate"
    endpoint = "us-east-1.linodeobjects.com"
    # ... see main.tf for full config
  }
}
```

### Option 3: HashiCorp Vault

For secrets management (not state), integrate Vault:

```hcl
provider "vault" {
  address = "https://vault.example.com"
}

data "vault_generic_secret" "linode" {
  path = "secret/linode"
}

provider "linode" {
  token = data.vault_generic_secret.linode.data["token"]
}
```

## Quick Start

```bash
# 1. Set your Linode token
export TF_VAR_linode_token="your-token-here"

# 2. Initialize
terraform init

# 3. Plan (preview changes)
terraform plan

# 4. Apply
terraform apply

# 5. Get kubeconfig
terraform output -raw kubeconfig > ~/.kube/sspp-config
export KUBECONFIG=~/.kube/sspp-config
```

## Environment-Specific Deployments

```bash
# Development
cd environments/dev
terraform init && terraform apply -var="environment=dev"

# Production
cd environments/prod
terraform init && terraform apply -var="environment=prod"
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `linode_token` | API token (required) | - |
| `environment` | dev, staging, prod | `dev` |
| `region` | Linode region | `us-east` |
| `k8s_version` | Kubernetes version | `1.29` |
| `node_type` | Instance type | `g6-standard-2` |
| `node_count` | Initial nodes | `3` |
| `allowed_ips` | IPs for K8s API access | `["0.0.0.0/0"]` |

## Outputs

```bash
terraform output kubeconfig      # Cluster credentials
terraform output cluster_id      # LKE cluster ID  
terraform output cluster_endpoint # K8s API URL
terraform output backup_bucket   # Object storage bucket name
```

## Related Resources

| Resource | Location |
|----------|----------|
| Kubernetes Manifests | [../k8s/](../k8s/) |
| Article Reference | [Part 7: Terraform IaC](../../articles/07-terraform-infrastructure-as-code.md) |

# Production
cd environments/prod
terraform init && terraform apply
```

## Required Variables

Create `terraform.tfvars`:

```hcl
linode_token = "your-api-token"
environment  = "prod"
region       = "us-east"
```

## Outputs

After apply:
- `cluster_id` - LKE cluster ID
- `kubeconfig_path` - Path to kubeconfig file
- `api_endpoint` - API public endpoint
