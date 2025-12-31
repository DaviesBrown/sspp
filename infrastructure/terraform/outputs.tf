output "cluster_id" {
  description = "Kubernetes cluster ID"
  value       = linode_lke_cluster.sspp_cluster.id
}

output "cluster_endpoint" {
  description = "Kubernetes cluster endpoint"
  value       = linode_lke_cluster.sspp_cluster.api_endpoints[0]
}

output "kubeconfig" {
  description = "Kubeconfig for cluster access"
  value       = linode_lke_cluster.sspp_cluster.kubeconfig[0].raw_config
  sensitive   = true
}

output "postgres_host" {
  description = "PostgreSQL host"
  value       = linode_database_postgresql.sspp_db.host_primary
  sensitive   = true
}

output "postgres_port" {
  description = "PostgreSQL port"
  value       = linode_database_postgresql.sspp_db.port
}

output "backup_bucket" {
  description = "Backup storage bucket"
  value       = linode_object_storage_bucket.backups.label
}
