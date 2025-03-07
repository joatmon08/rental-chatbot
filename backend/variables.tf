variable "region" {
  type        = string
  description = "AWS region for resources"
  default     = "us-east-1"
}

variable "name" {
  type        = string
  description = "Name of resources"
  default     = "rentals"
}

variable "titan_model_id" {
  type        = string
  description = "Model ID for Bedrock embeddings"
  default     = "amazon.titan-embed-text-v2:0"
}
