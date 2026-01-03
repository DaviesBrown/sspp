# LKE Cluster Module
# Reusable module for creating Linode Kubernetes Engine clusters

resource "linode_lke_cluster" "cluster" {
  label       = var.cluster_name
  k8s_version = var.k8s_version
  region      = var.region
  tags        = var.tags

  pool {
    type  = var.node_type
    count = var.node_count

    autoscaler {
      min = var.autoscaler_min
      max = var.autoscaler_max
    }
  }

  control_plane {
    high_availability = var.high_availability
  }
}

# Save kubeconfig to local file
resource "local_file" "kubeconfig" {
  content         = base64decode(linode_lke_cluster.cluster.kubeconfig)
  filename        = "${path.module}/kubeconfig"
  file_permission = "0600"
}
