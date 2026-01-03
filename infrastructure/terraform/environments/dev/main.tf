# Development Environment Configuration
terraform {
  required_version = ">= 1.6.0"
  
  backend "s3" {
    bucket                      = "sspp-terraform-state"
    key                         = "dev/terraform.tfstate"
    region                      = "us-east-1"
    endpoint                    = "us-east-1.linodeobjects.com"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
  }
}

provider "linode" {
  token = var.linode_token
}

variable "linode_token" {
  description = "Linode API token"
  type        = string
  sensitive   = true
}

module "dev_cluster" {
  source = "../../modules/lke-cluster"

  cluster_name      = "sspp-dev"
  region            = "us-east"
  k8s_version       = "1.28"
  node_type         = "g6-standard-2"  # Smaller nodes for dev
  node_count        = 2
  autoscaler_min    = 2
  autoscaler_max    = 5
  high_availability = false  # Dev doesn't need HA
  tags              = ["sspp", "dev", "managed-by-terraform"]
}

output "cluster_id" {
  value = module.dev_cluster.cluster_id
}

output "kubeconfig_path" {
  value = module.dev_cluster.kubeconfig_path
}
