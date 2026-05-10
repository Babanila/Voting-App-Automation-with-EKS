# S3 Bucket Outputs
output "bucket_name" {
  description = "Terraform state bucket name"

  value = local.resolved_bucket_name
}

output "bucket_arn" {
  description = "Terraform state bucket ARN"

  value = local.resolved_bucket_arn
}

output "bucket_region" {
  description = "AWS region hosting the Terraform state bucket"

  value = data.aws_region.current.name
}


# DynamoDB Table Outputs
output "dynamodb_table_name" {
  description = "Terraform lock table name"

  value = local.resolved_table_name
}

output "dynamodb_table_arn" {
  description = "Terraform lock table ARN"

  value = local.resolved_table_arn
}
