terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.89.0"
    }
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "~> 2.3.1"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Repository = "joatmon08/rental-chatbot"
    }
  }
}

provider "opensearch" {
  url         = aws_opensearchserverless_collection.rentals.collection_endpoint
  healthcheck = false
}