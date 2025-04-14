resource "hcp_hvn" "rental" {
  hvn_id         = var.name
  cloud_provider = "aws"
  region         = var.region
  cidr_block     = var.cidr_block
}

resource "hcp_aws_network_peering" "rental" {
  peering_id      = "${var.name}-peering"
  hvn_id          = hcp_hvn.rental.hvn_id
  peer_vpc_id     = module.vpc.vpc_id
  peer_account_id = module.vpc.vpc_owner_id
  peer_vpc_region = var.region
}

data "hcp_aws_network_peering" "rental" {
  hvn_id                = hcp_hvn.rental.hvn_id
  peering_id            = hcp_aws_network_peering.rental.peering_id
  wait_for_active_state = true
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = hcp_aws_network_peering.rental.provider_peering_id
  auto_accept               = true
}
resource "hcp_hvn_route" "rental" {
  hvn_link         = hcp_hvn.rental.self_link
  hvn_route_id     = "${var.name}-route"
  destination_cidr = module.vpc.vpc_cidr_block
  target_link      = data.hcp_aws_network_peering.rental.self_link
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

data "aws_secretsmanager_secret" "database" {
  arn = aws_rds_cluster.postgresql.master_user_secret.0.secret_arn
}

data "aws_secretsmanager_secret_version" "database" {
  secret_id = data.aws_secretsmanager_secret.database.id
}

resource "vault_kv_secret_v2" "database" {
  mount = vault_mount.payments.path
  name  = "database"
  data_json = jsonencode(
    {
      username = aws_rds_cluster.postgresql.master_username
      password = data.aws_secretsmanager_secret_version.database.secret_string
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
  masking_character = "42"
  template          = vault_transform_template.ccn.name
  allowed_roles     = [local.transform_role]
}

resource "vault_transform_role" "bookings" {
  path            = vault_mount.transform_rental.path
  name            = local.transform_role
  transformations = [vault_transform_transformation.payments_ccn.name, local.address_transformation_name]
}
