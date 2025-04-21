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

variable "tags" {
  type        = map(string)
  description = "Tags to add to resources"
  default = {
    Repository = "joatmon08/rental-chatbot//backend"
  }
}

variable "table_name" {
  type        = string
  description = "Name of table for vector store in RDS database"
  default     = "bedrock_integration.bedrock_kb"
}

variable "primary_key_field" {
  description = "The name of the field in which Bedrock stores the ID for each entry."
  type        = string
  default     = "id"
}

variable "metadata_field" {
  description = "The name of the field in which Amazon Bedrock stores metadata about the vector store."
  type        = string
  default     = "metadata"
}

variable "text_field" {
  description = "The name of the field in which Amazon Bedrock stores the raw text from your data."
  type        = string
  default     = "chunks"
}

variable "vector_field" {
  description = "The name of the field where the vector embeddings are stored"
  type        = string
  default     = "embedding"
}