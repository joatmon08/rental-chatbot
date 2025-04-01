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

resource "vault_mount" "payments" {
  path        = "payments"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_kv_secret_v2" "database" {
  mount = vault_mount.payments.path
  name  = "database"
  data_json = jsonencode(
    {
      username = random_pet.db_username.id,
      password = random_password.db_password.result
      host     = aws_rds_cluster.postgresql.endpoint
      port     = aws_rds_cluster.postgresql.port
      db_name  = aws_rds_cluster.postgresql.database_name
    }
  )
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

resource "vault_mount" "transform_rental" {
  path = "transform"
  type = "transform"
}

resource "vault_transform_template" "ccn" {
  path    = vault_mount.transform_rental.path
  name    = "ccn"
  type    = "regex"
  pattern = "(\\d{4})(\\d{4})(\\d{4})\\d{4}"
}

resource "vault_transform_template" "address" {
  path    = vault_mount.transform_rental.path
  name    = "address"
  type    = "regex"
  pattern = "([A-Za-z0-9]+( [A-Za-z0-9]+)+)"
}

locals {
  address_transformation_name = "address"
}

data "http" "example" {
  url = "${hcp_vault_cluster.rental.vault_public_endpoint_url}/v1/transform/transformations/tokenization/${local.address_transformation_name}"

  method = "POST"

  request_body = jsonencode({
    allowed_roles    = ["payments"]
    deletion_allowed = true
    convergent       = true
  })

  request_headers = {
    Accept            = "application/json"
    X-Vault-Token     = hcp_vault_cluster_admin_token.rental.token
    X-Vault-Namespace = hcp_vault_cluster.rental.namespace
  }

  lifecycle {
    postcondition {
      condition     = contains([200, 201, 204], self.status_code)
      error_message = "Status code invalid"
    }
  }
}

resource "vault_transform_transformation" "payments_ccn" {
  path              = vault_mount.transform_rental.path
  name              = "ccn"
  type              = "masking"
  masking_character = "*"
  template          = vault_transform_template.ccn.name
  allowed_roles     = ["payments"]
}

resource "vault_transform_role" "payments" {
  path            = vault_mount.transform_rental.path
  name            = "payments"
  transformations = [vault_transform_transformation.payments_ccn.name, local.address_transformation_name]
}
