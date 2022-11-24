terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind" # docs: https://registry.terraform.io/providers/tehcyx/kind/latest/docs/resources/cluster
      version = "0.0.15"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.7.1"
    }
  }
}

provider "kind" {}

provider "kubectl" {
  host                   = kind_cluster.main.endpoint
  cluster_ca_certificate = kind_cluster.main.cluster_ca_certificate
  client_certificate     = kind_cluster.main.client_certificate
  client_key             = kind_cluster.main.client_key
}

provider "helm" {
  kubernetes {
    host                   = kind_cluster.main.endpoint
    cluster_ca_certificate = kind_cluster.main.cluster_ca_certificate
    client_certificate     = kind_cluster.main.client_certificate
    client_key             = kind_cluster.main.client_key
  }
}
