terraform {
  required_version = ">= 1.0"
  
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
  
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "linode" {
  token = var.linode_token
}

provider "kubernetes" {
  host                   = linode_lke_cluster.sspp_cluster.kubeconfig[0].host
  token                  = linode_lke_cluster.sspp_cluster.kubeconfig[0].token
  cluster_ca_certificate = base64decode(linode_lke_cluster.sspp_cluster.kubeconfig[0].cluster_ca_certificate)
}
