resource "hcp_hvn" "rental" {
  hvn_id         = var.name
  cloud_provider = "aws"
  region         = var.region
  cidr_block     = var.cidr_block
}

# resource "hcp_aws_network_peering" "rental" {
#   peering_id      = "${var.name}-peering"
#   hvn_id          = hcp_hvn.rental.hvn_id
#   peer_vpc_id     = module.vpc.vpc_id
#   peer_account_id = module.vpc.vpc_owner_id
#   peer_vpc_region = var.region
# }

# data "hcp_aws_network_peering" "rental" {
#   hvn_id                = hcp_hvn.rental.hvn_id
#   peering_id            = hcp_aws_network_peering.rental.peering_id
#   wait_for_active_state = true
# }

# resource "aws_vpc_peering_connection_accepter" "peer" {
#   vpc_peering_connection_id = hcp_aws_network_peering.rental.provider_peering_id
#   auto_accept               = true
# }
# resource "hcp_hvn_route" "rental" {
#   hvn_link         = hcp_hvn.rental.self_link
#   hvn_route_id     = "${var.name}-route"
#   destination_cidr = module.vpc.vpc_cidr_block
#   target_link      = data.hcp_aws_network_peering.rental.self_link
# }

resource "hcp_vault_cluster" "rental" {
  cluster_id      = var.name
  hvn_id          = hcp_hvn.rental.hvn_id
  tier            = "plus_small"
  public_endpoint = true
}

resource "hcp_vault_cluster_admin_token" "rental" {
  cluster_id = hcp_vault_cluster.rental.cluster_id
}