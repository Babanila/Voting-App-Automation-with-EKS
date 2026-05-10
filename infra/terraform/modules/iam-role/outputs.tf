# Role Outputs
output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.this.name
}

output "role_id" {
  description = "ID of the IAM role"
  value       = aws_iam_role.this.id
}

output "role_unique_id" {
  description = "Unique ID of the IAM role"
  value       = aws_iam_role.this.unique_id
}

output "role_path" {
  description = "Path of the IAM role"
  value       = aws_iam_role.this.path
}


# Assume Role Policy
output "assume_role_policy" {
  description = "The assume role policy document"
  value       = local.assume_role_policy
}


# Instance Profile Outputs
output "instance_profile_arn" {
  description = "ARN of the instance profile"
  value       = var.create_instance_profile ? aws_iam_instance_profile.this[0].arn : ""
}

output "instance_profile_name" {
  description = "Name of the instance profile"
  value       = var.create_instance_profile ? aws_iam_instance_profile.this[0].name : ""
}


# Policy Outputs
output "policy_arns" {
  description = "Map of created policy ARNs"
  value = {
    for k, v in aws_iam_policy.this : k => v.arn
  }
}
