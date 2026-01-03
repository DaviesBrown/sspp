# Production Environment Configuration
terraform {
  required_version = ">= 1.6.0"
  
  backend "s3" {
    bucket                      = "sspp-terraform-state"
    key                         = "prod/terraform.tfstate"
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

module "prod_cluster" {
  source = "../../modules/lke-cluster"

  cluster_name      = "sspp-prod"
  region            = "us-east"
  k8s_version       = "1.28"
  node_type         = "g6-standard-4"  # Larger nodes for prod
  node_count        = 3
  autoscaler_min    = 3
  autoscaler_max    = 10
  high_availability = true  # Production needs HA
  tags              = ["sspp", "prod", "managed-by-terraform"]
}

output "cluster_id" {
  value = module.prod_cluster.cluster_id
}

output "kubeconfig_path" {
  value = module.prod_cluster.kubeconfig_path
}
