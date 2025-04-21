data "aws_caller_identity" "current" {}

data "vault_kv_secret_v2" "bucket" {
  mount = "listings"
  name  = "bucket"
}

resource "aws_iam_policy" "bedrock" {
  name        = "bedrock-${var.name}"
  path        = "/"
  description = "Allow Bedrock Knowledge Base to invoke model"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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

resource "aws_iam_policy" "bedrock_s3" {
  name        = "bedrock-s3-${var.name}"
  path        = "/"
  description = "Allow Bedrock Knowledge Base to access S3 bucket"

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
      }
    ]
  })
}

resource "aws_iam_policy" "bedrock_rds" {
  name        = "bedrock-rds-${var.name}"
  path        = "/"
  description = "Allow Bedrock Knowledge Base to access RDS database"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:DescribeDBClusters",
        ],
        Effect   = "Allow",
        Resource = local.database_cluster_arn
      },
      {
        Action = [
          "rds-data:BatchExecuteStatement",
          "rds-data:ExecuteStatement"
        ],
        Effect   = "Allow",
        Resource = local.database_cluster_arn
      },
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Effect   = "Allow",
        Resource = local.database_secrets_arn
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

resource "aws_iam_role_policy_attachment" "bedrock_s3" {
  role       = aws_iam_role.bedrock.name
  policy_arn = aws_iam_policy.bedrock_s3.arn
}

resource "aws_iam_role_policy_attachment" "bedrock_rds" {
  role       = aws_iam_role.bedrock.name
  policy_arn = aws_iam_policy.bedrock_rds.arn
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