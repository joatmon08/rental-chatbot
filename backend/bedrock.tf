data "aws_caller_identity" "current" {}

data "vault_kv_secret_v2" "bucket" {
  mount = "listings"
  name  = "bucket"
}

resource "aws_iam_policy" "bedrock" {
  name        = "bedrock-${var.name}"
  path        = "/"
  description = "Allow Bedrock Knowledge Base to access S3 bucket with rentals"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
        ],
        Effect   = "Allow",
        Resource = data.vault_kv_secret_v2.bucket.data.arn,
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Action = [
          "s3:GetObject",
        ],
        Effect   = "Allow",
        Resource = "${data.vault_kv_secret_v2.bucket.data.arn}/*",
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Action = [
          "aoss:APIAccessAll"
        ],
        Effect   = "Allow",
        Resource = aws_opensearchserverless_collection.rentals.arn,
      },
      {
        Action = [
          "bedrock:InvokeModel"
        ],
        Effect   = "Allow",
        Resource = data.aws_bedrock_foundation_model.embedding.model_arn,
      }
    ]
  })
}

resource "aws_iam_role" "bedrock" {
  name_prefix = "bedrock-${var.name}-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        },
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          },
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bedrock" {
  role       = aws_iam_role.bedrock.name
  policy_arn = aws_iam_policy.bedrock.arn
}

data "aws_bedrock_foundation_model" "embedding" {
  model_id = var.titan_model_id
}

resource "aws_bedrockagent_knowledge_base" "rentals" {
  name     = var.name
  role_arn = aws_iam_role.bedrock.arn
  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = data.aws_bedrock_foundation_model.embedding.model_arn
    }
    type = "VECTOR"
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"

    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.rentals.arn
      vector_index_name = opensearch_index.bedrock_knowledge_base.name
      field_mapping {
        vector_field   = local.vector_field
        text_field     = local.text_field
        metadata_field = local.metadata_field
      }
    }
  }
}

resource "aws_bedrockagent_data_source" "listings" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.rentals.id
  name              = "listings"
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = data.vault_kv_secret_v2.bucket.data.arn
    }
  }
}

# resource "awscc_bedrock_knowledge_base" "bookings" {
#   name        = "${var.name}-bookings"
#   description = "Database of bookings for vacation rentals"
#   role_arn    = aws_iam_role.bedrock.arn

#   knowledge_base_configuration = {
#     type = "SQL"
#     sql_knowledge_base_configuration = {
#       type = "REDSHIFT"
#       redshift_configuration = {
#         query_engine_configuration = {
#           serverless_configuration = var.sql_kb_workgroup_arn == null ? null : {
#             workgroup_arn = var.sql_kb_workgroup_arn
#             auth_configuration = var.serverless_auth_configuration
#           }
#           provisioned_configuration = var.provisioned_config_cluster_identifier == null ? null : {
#             cluster_identifier = var.provisioned_config_cluster_identifier
#             auth_configuration = var.provisioned_auth_configuration
#           } 
#           type = var.redshift_query_engine_type
#         }
#         query_generation_configuration = var.query_generation_configuration
#         storage_configurations = var.redshift_storage_configuration
#       }

#     }
#   }

# }