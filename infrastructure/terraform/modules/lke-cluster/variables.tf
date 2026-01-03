variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "region" {
  description = "Linode region"
  type        = string
}

variable "node_type" {
  description = "Linode instance type for nodes"
  type        = string
  default     = "g6-standard-2"
}

variable "node_count" {
  description = "Initial number of nodes"
  type        = number
  default     = 3
}

variable "autoscaler_min" {
  description = "Minimum number of nodes for autoscaling"
  type        = number
  default     = 2
}

variable "autoscaler_max" {
  description = "Maximum number of nodes for autoscaling"
  type        = number
  default     = 10
}

variable "high_availability" {
  description = "Enable high availability for control plane"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags for the cluster"
  type        = list(string)
  default     = []
}
