terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.103.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.6.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4.5"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.25.0"
    }
  }
}

provider "hcp" {
  project_id = var.hcp_project_id
}

provider "vault" {
  address   = hcp_vault_cluster.rental.vault_public_endpoint_url
  token     = hcp_vault_cluster_admin_token.rental.token
  namespace = hcp_vault_cluster.rental.namespace
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Repository = "joatmon08/rental-chatbot"
    }
  }
}

provider "postgresql" {
  alias           = "admin"
  host            = aws_rds_cluster.postgresql.endpoint
  port            = aws_rds_cluster.postgresql.port
  database        = aws_rds_cluster.postgresql.database_name
  username        = aws_rds_cluster.postgresql.master_username
  password        = aws_rds_cluster.postgresql.master_password
  sslmode         = "require"
  connect_timeout = 15
}

provider "postgresql" {
  alias           = "bedrock_user"
  host            = aws_rds_cluster.postgresql.endpoint
  port            = aws_rds_cluster.postgresql.port
  database        = aws_rds_cluster.postgresql.database_name
  username        = aws_rds_cluster.postgresql.master_username
  password        = aws_rds_cluster.postgresql.master_password
  superuser       = false
  sslmode         = "require"
  connect_timeout = 15
}
