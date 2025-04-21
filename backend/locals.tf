locals {
  database_cluster_arn = data.terraform_remote_state.infrastructure.outputs.bedrock_database_arn
  database_secrets_arn = data.terraform_remote_state.infrastructure.outputs.bedrock_database_credentials_arn
  database_name        = data.terraform_remote_state.infrastructure.outputs.bedrock_database_name
}
