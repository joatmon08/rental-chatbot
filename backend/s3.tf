locals {
  uuid = "ded1cd81-87d8-ebfb-2072-8a490224613a"
}

resource "aws_s3_bucket" "rentals" {
  bucket        = "${var.name}-${local.uuid}"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "rentals" {
  bucket = aws_s3_bucket.rentals.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "rentals" {
  depends_on = [aws_s3_bucket_ownership_controls.rentals]

  bucket = aws_s3_bucket.rentals.id
  acl    = "private"
}

