resource "vault_mount" "listings" {
  path        = "listings"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_kv_secret_v2" "listings" {
  mount = vault_mount.listings.path
  name  = "bucket"
  data_json = jsonencode(
    {
      arn  = aws_s3_bucket.rentals.arn
      name = aws_s3_bucket.rentals.name
    }
  )
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
      username = aws_rds_cluster.postgresql.master_username
      password = aws_rds_cluster.postgresql.master_password
      host     = aws_rds_cluster.postgresql.endpoint
      port     = aws_rds_cluster.postgresql.port
      db_name  = aws_rds_cluster.postgresql.database_name
    }
  )
}

resource "vault_kv_secret_v2" "database_bedrock" {
  mount = vault_mount.payments.path
  name  = "bedrock"
  data_json = jsonencode(
    {
      username = postgresql_role.bedrock.name
      password = random_password.bedrock_database.result
      host     = aws_rds_cluster.postgresql.endpoint
      port     = aws_rds_cluster.postgresql.port
      db_name  = aws_rds_cluster.postgresql.database_name
    }
  )
}

resource "vault_mount" "transit_rental" {
  path                      = "transit/${var.name}"
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
  path = "transform/${var.name}"
  type = "transform"
}

locals {
  address_transformation_name = "address"
  transform_role              = "bookings"
}

resource "vault_transform_template" "ccn" {
  path    = vault_mount.transform_rental.path
  name    = "ccn"
  type    = "regex"
  pattern = "(\\d{8,12})\\d{4}"
}

resource "vault_transform_template" "address" {
  path    = vault_mount.transform_rental.path
  name    = local.address_transformation_name
  type    = "regex"
  pattern = "([A-Za-z0-9]+( [A-Za-z0-9]+)+)"
}

data "http" "example" {
  url = "${hcp_vault_cluster.rental.vault_public_endpoint_url}/v1/${vault_mount.transform_rental.path}/transformations/tokenization/${local.address_transformation_name}"

  method = "POST"

  request_body = jsonencode({
    allowed_roles    = [local.transform_role]
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
  allowed_roles     = [local.transform_role]
}

resource "vault_transform_role" "bookings" {
  path            = vault_mount.transform_rental.path
  name            = local.transform_role
  transformations = [vault_transform_transformation.payments_ccn.name, local.address_transformation_name]
}
