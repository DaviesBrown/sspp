# =============================================================================
# SSPP Infrastructure - Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Required (set via TF_VAR_linode_token or terraform.tfvars)
# -----------------------------------------------------------------------------

variable "linode_token" {
  description = "Linode API token"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Environment
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "region" {
  description = "Linode region"
  type        = string
  default     = "us-east"
}

# -----------------------------------------------------------------------------
# Kubernetes Cluster
# -----------------------------------------------------------------------------

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "node_type" {
  description = "Linode instance type for nodes"
  type        = string
  default     = "g6-standard-2" # 2 vCPU, 4GB RAM
}

variable "node_count" {
  description = "Initial number of nodes"
  type        = number
  default     = 3
}

# -----------------------------------------------------------------------------
# Security
# -----------------------------------------------------------------------------

variable "allowed_ips" {
  description = "IP addresses allowed to access K8s API"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict in production!
}

# -----------------------------------------------------------------------------
# Optional Features
# -----------------------------------------------------------------------------

variable "manage_dns" {
  description = "Whether to manage DNS records"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

