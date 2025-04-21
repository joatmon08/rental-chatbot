terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.89.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.37.0"
    }
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "~> 2.3.1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.7.0"
    }
  }
}

provider "awscc" {
  region = var.region
}

provider "aws" {
  region = var.region
  default_tags {
    tags = var.tags
  }
}

provider "opensearch" {
  url         = aws_opensearchserverless_collection.rentals.collection_endpoint
  healthcheck = false
}

data "terraform_remote_state" "infrastructure" {
  backend = "remote"

  config = {
    organization = "rosemary-production"
    workspaces = {
      name = "infrastructure"
    }
  }
}

provider "vault" {
  address   = data.terraform_remote_state.infrastructure.outputs.vault_address
  namespace = data.terraform_remote_state.infrastructure.outputs.vault_namespace
  token     = data.terraform_remote_state.infrastructure.outputs.vault_token
}
