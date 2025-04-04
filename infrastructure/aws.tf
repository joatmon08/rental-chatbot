data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

resource "random_pet" "db_username" {
  length = 1
}

resource "random_password" "db_password" {
  length           = 16
  override_special = "!#$"
}

locals {
  subnets = cidrsubnets(var.vpc_cidr_block, 8, 8, 8, 8, 8, 8, 8, 8, 8)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name            = var.name
  cidr            = var.vpc_cidr_block
  azs             = data.aws_availability_zones.available.names
  public_subnets  = slice(local.subnets, 0, 3)
  private_subnets = slice(local.subnets, 3, 6)

  manage_default_route_table = true
  default_route_table_tags   = { DefaultRouteTable = true }

  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_dns_hostnames = true

  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true
  create_database_nat_gateway_route      = true

  database_subnets = slice(local.subnets, 6, 9)
  database_subnet_group_tags = {
    Purpose = "database"
  }

  default_vpc_tags = {
    HCP_Peer = jsonencode([var.cidr_block])
  }

}

resource "aws_security_group" "database" {
  name        = "${var.name}-database"
  description = "Allow database inbound traffic and all outbound traffic"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "allow_vpc_traffic" {
  security_group_id = aws_security_group.database.id
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}

resource "aws_vpc_security_group_ingress_rule" "allow_hcp_traffic" {
  security_group_id = aws_security_group.database.id
  cidr_ipv4         = var.cidr_block
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}

resource "aws_vpc_security_group_ingress_rule" "allow_client_traffic" {
  count             = var.client_cidr_block != null ? 1 : 0
  security_group_id = aws_security_group.database.id
  cidr_ipv4         = var.client_cidr_block
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.database.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_rds_cluster" "postgresql" {
  cluster_identifier     = var.name
  engine                 = "aurora-postgresql"
  availability_zones     = slice(data.aws_availability_zones.available.names, 0, 3)
  database_name          = var.name
  skip_final_snapshot    = true
  master_username        = random_pet.db_username.id
  master_password        = random_password.db_password.result
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.database.id]
}

resource "aws_rds_cluster_instance" "postgresql" {
  count              = 1
  identifier         = "${var.name}-payments"
  cluster_identifier = aws_rds_cluster.postgresql.id
  instance_class     = var.db_instance_class
  engine             = aws_rds_cluster.postgresql.engine
  engine_version     = aws_rds_cluster.postgresql.engine_version
}
