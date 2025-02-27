output "vault_address" {
  value = hcp_vault_cluster.rental.vault_public_endpoint_url
}

output "vault_token" {
  value     = hcp_vault_cluster_admin_token.rental.token
  sensitive = true
}

output "vault_namespace" {
  value = hcp_vault_cluster.rental.namespace
}

