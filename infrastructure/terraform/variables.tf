variable "linode_token" {
  description = "Linode API token"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "Linode region"
  type        = string
  default     = "us-east"
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "sspp-cluster"
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_count" {
  description = "Number of nodes in the default pool"
  type        = number
  default     = 3
}

variable "node_type" {
  description = "Linode instance type for nodes"
  type        = string
  default     = "g6-standard-2" # 2 CPU, 4GB RAM
}

variable "postgres_plan" {
  description = "PostgreSQL database plan"
  type        = string
  default     = "g6-nanode-1" # 1GB RAM
}

variable "redis_plan" {
  description = "Redis instance plan"
  type        = string
  default     = "g6-nanode-1"
}
