# =============================================================================
# SSPP Infrastructure - Main Configuration
# =============================================================================
# All infrastructure defined in one place. State can be stored in:
# - Terraform Cloud (recommended)
# - HashiCorp Vault
# - S3-compatible storage (Linode Object Storage)
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 2.9"
    }
  }

  # =============================================================================
  # BACKEND OPTIONS - Uncomment ONE of the following:
  # =============================================================================

  # Option 1: Terraform Cloud (recommended - free tier available)
  # Handles state, locking, secrets, and runs
  # cloud {
  #   organization = "your-org"
  #   workspaces {
  #     name = "sspp-prod"
  #   }
  # }

  # Option 2: Local state (development only)
  backend "local" {
    path = "terraform.tfstate"
  }

  # Option 3: S3-compatible (Linode Object Storage)
  # backend "s3" {
  #   bucket                      = "sspp-terraform-state"
  #   key                         = "terraform.tfstate"
  #   region                      = "us-east-1"
  #   endpoint                    = "us-east-1.linodeobjects.com"
  #   skip_credentials_validation = true
  #   skip_region_validation      = true
  #   skip_metadata_api_check     = true
  # }
}

# =============================================================================
# PROVIDER
# =============================================================================

provider "linode" {
  token = var.linode_token # Set via TF_VAR_linode_token or terraform.tfvars
}

# =============================================================================
# KUBERNETES CLUSTER (LKE)
# =============================================================================

resource "linode_lke_cluster" "main" {
  label       = "sspp-${var.environment}"
  k8s_version = var.k8s_version
  region      = var.region
  tags        = ["sspp", var.environment]

  pool {
    type  = var.node_type
    count = var.node_count

    autoscaler {
      min = var.node_count
      max = var.node_count * 2
    }
  }

  control_plane {
    high_availability = var.environment == "prod"
  }

  lifecycle {
    ignore_changes = [pool[0].count] # Let autoscaler manage
  }
}

# =============================================================================
# FIREWALL
# =============================================================================

resource "linode_firewall" "cluster" {
  label = "sspp-${var.environment}"
  tags  = ["sspp", var.environment]

  inbound {
    label    = "https"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "443"
    ipv4     = ["0.0.0.0/0"]
  }

  inbound {
    label    = "http"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "80"
    ipv4     = ["0.0.0.0/0"]
  }

  inbound {
    label    = "k8s-api"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "6443"
    ipv4     = var.allowed_ips
  }

  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"

  linodes = [for node in linode_lke_cluster.main.pool[0].nodes : node.instance_id]
}

# =============================================================================
# OBJECT STORAGE (Backups)
# =============================================================================

resource "linode_object_storage_bucket" "backups" {
  cluster = "${var.region}-1"
  label   = "sspp-backups-${var.environment}"

  lifecycle_rule {
    enabled = true
    id      = "expire-old-backups"
    expiration {
      days = 30
    }
  }
}

resource "linode_object_storage_key" "backups" {
  label = "sspp-backups-${var.environment}"
  bucket_access {
    bucket_name = linode_object_storage_bucket.backups.label
    cluster     = linode_object_storage_bucket.backups.cluster
    permissions = "read_write"
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "kubeconfig" {
  description = "Kubeconfig for the LKE cluster"
  value       = linode_lke_cluster.main.kubeconfig
  sensitive   = true
}

output "cluster_id" {
  description = "LKE cluster ID"
  value       = linode_lke_cluster.main.id
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = linode_lke_cluster.main.api_endpoints
}

output "backup_bucket" {
  description = "Object storage bucket for backups"
  value       = linode_object_storage_bucket.backups.label
}
