resource "postgresql_extension" "pgvector" {
  provider = postgresql.admin

  name = "vector"
}

resource "postgresql_schema" "bedrock" {
  provider = postgresql.admin

  name = "bedrock_integration"
}

resource "random_password" "bedrock_database" {
  length  = 16
  special = false
}

locals {
  postgresql_bedrock_user = "bedrock_user"
}

resource "aws_secretsmanager_secret" "bedrock_database" {
  name_prefix             = "${var.name}-bedrock-database-"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "bedrock_database" {
  secret_id = aws_secretsmanager_secret.bedrock_database.id
  secret_string_wo = jsonencode({
    username = local.postgresql_bedrock_user,
    password = random_password.bedrock_database.result
  })
  secret_string_wo_version = 1
}

data "aws_secretsmanager_secret_version" "bedrock_database" {
  secret_id = aws_secretsmanager_secret_version.bedrock_database.secret_id
}

resource "postgresql_role" "bedrock" {
  provider = postgresql.admin

  name      = local.postgresql_bedrock_user
  password  = random_password.bedrock_database.result
  superuser = false
  login     = true
}

resource "postgresql_grant" "bedrock" {
  provider = postgresql.admin

  database    = aws_rds_cluster.postgresql.database_name
  object_type = "schema"
  role        = postgresql_role.bedrock.name
  schema      = postgresql_schema.bedrock.name
  privileges  = ["ALL"]
}
