output "cluster_id" {
  description = "ID of the LKE cluster"
  value       = linode_lke_cluster.cluster.id
}

output "kubeconfig" {
  description = "Base64 encoded kubeconfig"
  value       = linode_lke_cluster.cluster.kubeconfig
  sensitive   = true
}

output "api_endpoints" {
  description = "Kubernetes API endpoints"
  value       = linode_lke_cluster.cluster.api_endpoints
}

output "pool" {
  description = "Node pool information"
  value       = linode_lke_cluster.cluster.pool
}

output "kubeconfig_path" {
  description = "Path to kubeconfig file"
  value       = local_file.kubeconfig.filename
}
