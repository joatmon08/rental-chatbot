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

output "vault_transit_path" {
  value = vault_mount.transit_rental.path
}

output "bedrock_database_name" {
  value = aws_rds_cluster.postgresql.database_name
}

output "bedrock_database_arn" {
  value = aws_rds_cluster.postgresql.arn
}