terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.103.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.6.0"
    }
  }
}

provider "hcp" {
  project_id = var.hcp_project_id
}

provider "vault" {
  address   = hcp_vault_cluster.rental.vault_public_endpoint_url
  token     = hcp_vault_cluster_admin_token.rental.token
  namespace = hcp_vault_cluster.rental.namespace
}