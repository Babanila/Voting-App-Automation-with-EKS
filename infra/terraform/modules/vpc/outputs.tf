# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "vpc_secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks of the VPC"
  value       = aws_vpc.this.secondary_cidr_blocks
}

output "vpc_main_route_table_id" {
  description = "ID of the main route table"
  value       = aws_vpc.this.main_route_table_id
}

output "vpc_default_network_acl_id" {
  description = "ID of the default network ACL"
  value       = aws_vpc.this.default_network_acl_id
}

output "vpc_default_security_group_id" {
  description = "ID of the default security group"
  value       = aws_vpc.this.default_security_group_id
}

output "vpc_enable_dns_hostnames" {
  description = "Whether DNS hostnames are enabled"
  value       = aws_vpc.this.enable_dns_hostnames
}

output "vpc_enable_dns_support" {
  description = "Whether DNS support is enabled"
  value       = aws_vpc.this.enable_dns_support
}


# Subnet Outputs
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  description = "List of public subnet ARNs"
  value       = aws_subnet.public[*].arn
}

output "public_subnets" {
  description = "Map of public subnet attributes"
  value = {
    for idx, subnet in aws_subnet.public : subnet.availability_zone => {
      id                = subnet.id
      arn               = subnet.arn
      cidr_block        = subnet.cidr_block
      availability_zone = subnet.availability_zone
    }
  }
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "private_subnet_arns" {
  description = "List of private subnet ARNs"
  value       = aws_subnet.private[*].arn
}

output "private_subnets" {
  description = "Map of private subnet attributes"
  value = {
    for idx, subnet in aws_subnet.private : subnet.availability_zone => {
      id                = subnet.id
      arn               = subnet.arn
      cidr_block        = subnet.cidr_block
      availability_zone = subnet.availability_zone
    }
  }
}

output "database_subnet_ids" {
  description = "List of database subnet IDs"
  value       = aws_subnet.database[*].id
}

output "database_subnet_arns" {
  description = "List of database subnet ARNs"
  value       = aws_subnet.database[*].arn
}

output "database_subnets" {
  description = "Map of database subnet attributes"
  value = {
    for idx, subnet in aws_subnet.database : subnet.availability_zone => {
      id                = subnet.id
      arn               = subnet.arn
      cidr_block        = subnet.cidr_block
      availability_zone = subnet.availability_zone
    }
  }
}

output "elasticache_subnet_ids" {
  description = "List of ElastiCache subnet IDs"
  value       = aws_subnet.elasticache[*].id
}


# Subnet Group Outputs
output "database_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = local.num_database_subnets > 0 ? aws_db_subnet_group.this[0].name : ""
}

output "database_subnet_group_id" {
  description = "ID of the database subnet group"
  value       = local.num_database_subnets > 0 ? aws_db_subnet_group.this[0].id : ""
}

output "elasticache_subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = local.num_elasticache_subnets > 0 ? aws_elasticache_subnet_group.this[0].name : ""
}


# Gateway Outputs
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = local.num_public_subnets > 0 ? aws_internet_gateway.this.id : ""
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "List of NAT Gateway public IPs"
  value       = aws_eip.nat[*].public_ip
}

output "nat_gateway_count" {
  description = "Number of NAT Gateways created"
  value       = local.nat_gateway_count
}


# Route Table Outputs
output "public_route_table_ids" {
  description = "List of public route table IDs"
  value       = aws_route_table.public[*].id
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = aws_route_table.private[*].id
}

output "database_route_table_ids" {
  description = "List of database route table IDs"
  value       = aws_route_table.database[*].id
}


# DHCP Options Outputs
output "dhcp_options_id" {
  description = "ID of the DHCP options"
  value       = var.enable_dhcp_options ? aws_vpc_dhcp_options.this[0].id : ""
}


# VPC Endpoints Outputs
output "vpc_endpoint_s3_id" {
  description = "ID of the S3 VPC endpoint"
  value       = var.enable_vpc_endpoints ? try(aws_vpc_endpoint.gateway["s3"].id, "") : ""
}

output "vpc_endpoint_dynamodb_id" {
  description = "ID of the DynamoDB VPC endpoint"
  value       = var.enable_vpc_endpoints ? try(aws_vpc_endpoint.gateway["dynamodb"].id, "") : ""
}

output "vpc_endpoint_ids" {
  description = "Map of VPC endpoint IDs"
  value = var.enable_vpc_endpoints ? merge(
    { for k, v in aws_vpc_endpoint.gateway : k => v.id },
    { for k, v in aws_vpc_endpoint.interface : k => v.id }
  ) : {}
}


# Flow Logs Outputs
output "flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = var.enable_flow_logs ? (var.flow_logs_destination_type == "cloud-watch-logs" ? aws_flow_log.cloudwatch[0].id : aws_flow_log.s3[0].id) : ""
}

output "flow_log_cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for flow logs"
  value       = var.enable_flow_logs && var.flow_logs_destination_type == "cloud-watch-logs" ? aws_cloudwatch_log_group.vpc_flow_logs[0].name : ""
}


# Availability Zones
output "availability_zones" {
  description = "List of availability zones used"
  value       = local.azs
}

output "azs_count" {
  description = "Number of availability zones"
  value       = length(local.azs)
}
