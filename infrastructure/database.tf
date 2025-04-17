resource "aws_db_subnet_group" "rental" {
  name       = var.name
  subnet_ids = module.vpc.public_subnets
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

ephemeral "random_password" "admin_database" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "admin_database" {
  name_prefix             = "${var.name}-admin-database-"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "admin_database" {
  secret_id = aws_secretsmanager_secret.admin_database.id
  secret_string_wo = jsonencode({
    username = random_pet.db_username.id
    password = ephemeral.random_password.admin_database.result
  })
  secret_string_wo_version = 1
}

data "aws_secretsmanager_secret_version" "admin_database" {
  secret_id = aws_secretsmanager_secret_version.admin_database.secret_id
}

resource "aws_rds_cluster" "postgresql" {
  cluster_identifier     = var.name
  engine                 = "aurora-postgresql"
  availability_zones     = slice(data.aws_availability_zones.available.names, 0, 3)
  database_name          = var.name
  skip_final_snapshot    = true
  master_username        = jsondecode(data.aws_secretsmanager_secret_version.admin_database.secret_string)["username"]
  master_password        = jsondecode(data.aws_secretsmanager_secret_version.admin_database.secret_string)["password"]
  db_subnet_group_name   = aws_db_subnet_group.rental.name
  vpc_security_group_ids = [aws_security_group.database.id]
  enable_http_endpoint   = true
}

resource "aws_rds_cluster_instance" "postgresql" {
  count               = 1
  identifier          = "${var.name}-payments"
  cluster_identifier  = aws_rds_cluster.postgresql.id
  instance_class      = var.db_instance_class
  engine              = aws_rds_cluster.postgresql.engine
  engine_version      = aws_rds_cluster.postgresql.engine_version
  publicly_accessible = true
}