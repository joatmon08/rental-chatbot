resource "hcp_hvn" "rental" {
  hvn_id         = var.name
  cloud_provider = "aws"
  region         = var.region
  cidr_block     = var.cidr_block
}

resource "hcp_vault_cluster" "rental" {
  cluster_id      = var.name
  hvn_id          = hcp_hvn.rental.hvn_id
  tier            = "plus_small"
  public_endpoint = true
}

resource "hcp_vault_cluster_admin_token" "rental" {
  cluster_id = hcp_vault_cluster.rental.cluster_id
}

resource "vault_mount" "transit_rental" {
  path                      = var.name
  type                      = "transit"
  description               = "Key ring for rental information"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 86400
}

resource "vault_transit_secret_backend_key" "listings" {
  backend               = vault_mount.transit_rental.path
  name                  = "listings"
  derived               = true
  convergent_encryption = true
  deletion_allowed      = true
}
