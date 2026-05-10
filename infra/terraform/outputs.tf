# VPC Outputs
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  value = module.vpc.database_subnet_ids
}

output "nat_gateway_ips" {
  value = module.vpc.nat_gateway_public_ips
}

output "database_subnet_group_name" {
  value = module.vpc.database_subnet_group_name
}


#  Security group IDs Output
output "security_groups" {
  value = {
    alb     = module.alb_sg.security_group_id
    web     = module.web_sg.security_group_id
    backend = module.backend_sg.security_group_id
    db      = module.db_sg.security_group_id
    bastion = module.bastion_sg.security_group_id
  }
}


# EKS Outputs
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}


# IAM Role Outputs
output "cloudwatch_role_arn" {
  description = "ARN of the CloudWatch IAM role"
  value       = module.cloudwatch_role.role_arn
}

output "cloudwatch_role_name" {
  description = "Name of the CloudWatch IAM role"
  value       = module.cloudwatch_role.role_name
}

output "cloudwatch_instance_profile_name" {
  description = "Name of the CloudWatch instance profile"
  value       = module.cloudwatch_role.instance_profile_name
}



# EC2 Instance Outputs
output "frontend_instance_ids" {
  description = "Map of frontend instance IDs by AZ"
  value = {
    for az, instance in aws_instance.frontend : az => instance.id
  }
}

output "frontend_public_ips" {
  description = "Map of frontend public IPs by AZ"
  value = {
    for az, instance in aws_instance.frontend : az => instance.public_ip
  }
}

output "frontend_private_ips" {
  description = "Map of frontend private IPs by AZ"
  value = {
    for az, instance in aws_instance.frontend : az => instance.private_ip
  }
}

output "backend_instance_ids" {
  description = "Map of backend instance IDs by AZ"
  value = {
    for az, instance in aws_instance.backend : az => instance.id
  }
}

output "backend_private_ips" {
  description = "Map of backend private IPs by AZ"
  value = {
    for az, instance in aws_instance.backend : az => instance.private_ip
  }
}

output "database_instance_ids" {
  description = "Map of database instance IDs by AZ"
  value = {
    for az, instance in aws_instance.database : az => instance.id
  }
}

output "database_private_ips" {
  description = "Map of database private IPs by AZ"
  value = {
    for az, instance in aws_instance.database : az => instance.private_ip
  }
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  value = aws_instance.bastion.private_ip
}

output "bastion_public_dns" {
  value = aws_instance.bastion.public_dns
}

output "bastion_az" {
  value = aws_instance.bastion.availability_zone
}
