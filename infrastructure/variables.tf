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