# Locals
locals {
  bucket_name = var.project_bucket_name
  table_name  = "tflock-${var.project_bucket_name}"

  common_tags = merge(
    {
      ManagedBy = "Terraform"
      Project   = var.project_bucket_name
    },
    var.tags
  )
}


# Existing Resources Lookup
data "aws_region" "current" {}
data "aws_s3_bucket" "existing" {
  count = var.create_bucket ? 0 : 1

  bucket = local.bucket_name
}

data "aws_dynamodb_table" "existing" {
  count = var.create_dynamodb_table ? 0 : 1

  name = local.table_name
}


# KMS Key for S3 Encryption
resource "aws_kms_key" "terraform_state" {
  count = var.create_bucket ? 1 : 0

  description             = "KMS key for Terraform remote state bucket"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(
    local.common_tags,
    {
      Name    = "${local.bucket_name}-kms"
      Purpose = "terraform-state-encryption"
    }
  )
}

resource "aws_kms_alias" "terraform_state" {
  count = var.create_bucket ? 1 : 0

  name          = "alias/${local.bucket_name}-terraform-state"
  target_key_id = aws_kms_key.terraform_state[0].key_id
}


# S3 Bucket
resource "aws_s3_bucket" "terraform_state" {
  count = var.create_bucket ? 1 : 0

  bucket = local.bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    local.common_tags,
    {
      Name    = local.bucket_name
      Purpose = "terraform-state"
    }
  )
}


# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  count = var.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.terraform_state[0].id

  versioning_configuration {
    status = "Enabled"
  }
}


# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  count = var.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.terraform_state[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_state[0].arn
      sse_algorithm     = "aws:kms"
    }

    bucket_key_enabled = true
  }
}


# S3 Public Access Block
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  count = var.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.terraform_state[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# S3 Bucket Ownership Controls
resource "aws_s3_bucket_ownership_controls" "terraform_state" {
  count = var.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.terraform_state[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}


# S3 Bucket Lifecycle Rules
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  count = var.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.terraform_state[0].id

  rule {
    id     = "noncurrent-version-retention"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}


# DynamoDB Table for Terraform Locking
resource "aws_dynamodb_table" "terraform_locks" {
  count = var.create_dynamodb_table ? 1 : 0

  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  deletion_protection_enabled = true

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    local.common_tags,
    {
      Name    = local.table_name
      Purpose = "terraform-state-locking"
    }
  )
}


# Unified Resource References
locals {
  resolved_bucket_name = var.create_bucket ? aws_s3_bucket.terraform_state[0].bucket : data.aws_s3_bucket.existing[0].bucket
  resolved_bucket_arn  = var.create_bucket ? aws_s3_bucket.terraform_state[0].arn : data.aws_s3_bucket.existing[0].arn
  resolved_table_name  = var.create_dynamodb_table ? aws_dynamodb_table.terraform_locks[0].name : data.aws_dynamodb_table.existing[0].name
  resolved_table_arn   = var.create_dynamodb_table ? aws_dynamodb_table.terraform_locks[0].arn : data.aws_dynamodb_table.existing[0].arn
}
