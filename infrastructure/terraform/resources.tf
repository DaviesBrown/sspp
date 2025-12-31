# Kubernetes Cluster
resource "linode_lke_cluster" "sspp_cluster" {
  label       = "${var.cluster_name}-${var.environment}"
  k8s_version = var.k8s_version
  region      = var.region
  tags        = ["sspp", var.environment]

  pool {
    type  = var.node_type
    count = var.node_count
    
    autoscaler {
      min = var.node_count
      max = var.node_count + 2
    }
  }
  
  lifecycle {
    ignore_changes = [
      pool[0].count
    ]
  }
}

# PostgreSQL Database
resource "linode_database_postgresql" "sspp_db" {
  label           = "sspp-postgres-${var.environment}"
  region          = var.region
  engine_id       = "postgresql/15.2"
  type            = var.postgres_plan
  cluster_size    = 1
  replication_type = "none"
  
  allow_list = [
    linode_lke_cluster.sspp_cluster.pool[0].nodes[0].instance_id
  ]
  
  tags = ["sspp", var.environment, "database"]
}

# Object Storage for backups
resource "linode_object_storage_bucket" "backups" {
  cluster = var.region
  label   = "sspp-backups-${var.environment}"
  
  lifecycle_rule {
    id      = "delete-old-backups"
    enabled = true
    
    expiration {
      days = 30
    }
  }
}

# Firewall for cluster
resource "linode_firewall" "cluster_firewall" {
  label = "sspp-cluster-firewall-${var.environment}"
  tags  = ["sspp", var.environment]

  inbound {
    label    = "allow-https"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "443"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "allow-http"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "80"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"

  linodes = linode_lke_cluster.sspp_cluster.pool[0].nodes[*].instance_id
}
