# Security Group Outputs
output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "ARN of the security group"
  value       = aws_security_group.this.arn
}

output "security_group_name" {
  description = "Name of the security group"
  value       = aws_security_group.this.name
}

output "security_group_vpc_id" {
  description = "VPC ID of the security group"
  value       = aws_security_group.this.vpc_id
}

output "security_group_description" {
  description = "Description of the security group"
  value       = aws_security_group.this.description
}


# Rule Outputs
output "ingress_rule_ids" {
  description = "Map of ingress rule IDs"
  value = {
    for idx, rule in aws_security_group_rule.ingress : idx => rule.id
  }
}

output "egress_rule_ids" {
  description = "Map of egress rule IDs"
  value = {
    for idx, rule in aws_security_group_rule.egress : idx => rule.id
  }
}
