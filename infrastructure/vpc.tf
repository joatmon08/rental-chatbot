# data "aws_availability_zones" "available" {
#   state = "available"

#   filter {
#     name   = "opt-in-status"
#     values = ["opt-in-not-required"]
#   }
# }

# resource "random_pet" "db_username" {
#   length = 1
# }

# locals {
#   subnets = cidrsubnets(var.vpc_cidr_block, 8, 8, 8, 8, 8, 8, 8, 8, 8)
# }

# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "5.19.0"

#   name            = var.name
#   cidr            = var.vpc_cidr_block
#   azs             = data.aws_availability_zones.available.names
#   public_subnets  = slice(local.subnets, 0, 3)
#   private_subnets = slice(local.subnets, 3, 6)

#   manage_default_route_table = true
#   default_route_table_tags   = { DefaultRouteTable = true }

#   enable_nat_gateway   = true
#   single_nat_gateway   = false
#   enable_dns_hostnames = true

#   default_vpc_tags = {
#     HCP_Peer = jsonencode([var.cidr_block])
#   }

# }
