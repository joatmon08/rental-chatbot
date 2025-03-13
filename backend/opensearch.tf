resource "aws_opensearchserverless_security_policy" "rentals_encryption" {
  name = var.name
  type = "encryption"
  policy = jsonencode({
    "Rules" = [
      {
        "Resource" = [
          "collection/${var.name}"
        ],
        "ResourceType" = "collection"
      },
    ],
    "AWSOwnedKey" = true
  })
}

resource "aws_opensearchserverless_security_policy" "rentals_network" {
  name = var.name
  type = "network"
  policy = jsonencode([{
    "Rules" = [
      {
        "Resource" = [
          "collection/${var.name}"
        ],
        "ResourceType" = "collection"
      },
      {
        "Resource" = [
          "collection/${var.name}"
        ],
        "ResourceType" = "dashboard"
      },
    ],
    "AllowFromPublic" = true,
  }])
}

resource "aws_opensearchserverless_access_policy" "rentals" {
  name        = var.name
  type        = "data"
  description = "read and write permissions"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "index",
          Resource = [
            "index/${var.name}/*"
          ],
          Permission = [
            "aoss:*"
          ]
        },
        {
          ResourceType = "collection",
          Resource = [
            "collection/${var.name}"
          ],
          Permission = [
            "aoss:*"
          ]
        }
      ],
      Principal = [
        aws_iam_role.bedrock.arn,
        data.aws_caller_identity.current.arn
      ]
    }
  ])
}

resource "aws_opensearchserverless_collection" "rentals" {
  name = var.name
  type = "VECTORSEARCH"

  depends_on = [
    aws_opensearchserverless_security_policy.rentals_encryption,
    aws_opensearchserverless_security_policy.rentals_network
  ]
}

locals {
  vector_field   = "bedrock-knowledge-base-default-vector"
  metadata_field = "AMAZON_BEDROCK_METADATA"
  text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
}

resource "opensearch_index" "bedrock_knowledge_base" {
  name                           = "bedrock-knowledge-base-default-index"
  number_of_shards               = "2"
  number_of_replicas             = "0"
  index_knn                      = true
  index_knn_algo_param_ef_search = "512"
  mappings                       = <<-EOF
    {
      "properties": {
        "${local.vector_field}": {
          "type": "knn_vector",
          "dimension": 1024,
          "method": {
            "name": "hnsw",
            "engine": "faiss",
            "parameters": {
              "m": 16,
              "ef_construction": 512
            },
            "space_type": "l2"
          }
        },
        "${local.metadata_field}": {
          "type": "text",
          "index": "false"
        },
        "${local.text_field}": {
          "type": "text",
          "index": "true"
        }
      }
    }
  EOF
}
