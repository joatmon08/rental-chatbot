variable "hcp_project_id" {
  type        = string
  description = "HCP Project ID"
}

variable "name" {
  type        = string
  description = "Name of HCP resources"
  default     = "rentals"
}

variable "region" {
  type        = string
  description = "AWS region for resources"
  default     = "us-east-1"
}

variable "cidr_block" {
  type        = string
  description = "CIDR block for HCP resources"
  default     = "172.25.16.0/20"
}

variable "postgres_db_version" {
  type        = string
  description = "PostgreSQL database version"
  default     = "16.4"
}

variable "db_instance_class" {
  type        = string
  default     = "db.r5.large"
  description = "Database instance class"
}

variable "vpc_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR Block for VPC"
}

variable "client_cidr_block" {
  type        = string
  default     = null
  description = "CIDR Block for client to connect for testing"
}

variable "titan_model_id" {
  type        = string
  description = "Model ID for Bedrock embeddings"
  default     = "amazon.titan-embed-text-v2:0"
}