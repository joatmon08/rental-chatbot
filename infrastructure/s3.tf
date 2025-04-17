resource "random_uuid" "rentals" {
  keepers = {
    name = var.name
  }
}

resource "aws_s3_bucket" "rentals" {
  bucket        = "${var.name}-${random_uuid.rentals.result}"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "rentals" {
  bucket = aws_s3_bucket.rentals.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "rentals" {
  bucket = aws_s3_bucket_ownership_controls.rentals.bucket
  acl    = "private"
}