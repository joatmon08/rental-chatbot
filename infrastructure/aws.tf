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

ephemeral "random_password" "db_password" {
  length           = 16
  override_special = "!#$"
}

resource "aws_rds_cluster" "postgresql" {
  cluster_identifier         = var.name
  engine                     = "aurora-postgresql"
  availability_zones         = slice(data.aws_availability_zones.available.names, 0, 3)
  database_name              = var.name
  skip_final_snapshot        = true
  master_username            = random_pet.db_username.id
  master_password_wo         = ephemeral.random_password.db_password.result
  master_password_wo_version = 1
}