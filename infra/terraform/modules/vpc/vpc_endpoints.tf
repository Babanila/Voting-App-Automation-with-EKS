# VPC Endpoints
locals {
  # Determine subnet IDs for interface endpoints
  vpc_endpoint_subnet_ids = var.vpc_endpoint_subnet_ids_type == "database" ? (
    aws_subnet.database[*].id
  ) : aws_subnet.private[*].id

  # Default VPC endpoints
  default_vpc_endpoints = {
    s3 = {
      service_name        = "com.amazonaws.${data.aws_region.current.name}.s3"
      vpc_endpoint_type   = "Gateway"
      private_dns_enabled = false
      security_group_ids  = []
    }
    dynamodb = {
      service_name        = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
      vpc_endpoint_type   = "Gateway"
      private_dns_enabled = false
      security_group_ids  = []
    }
  }
}


# Gateway VPC Endpoints (S3, DynamoDB)
resource "aws_vpc_endpoint" "gateway" {
  for_each = var.enable_vpc_endpoints ? {
    for k, v in merge(local.default_vpc_endpoints, var.vpc_endpoints) : k => v
    if v.vpc_endpoint_type == "Gateway"
  } : {}

  vpc_id            = aws_vpc.this.id
  service_name      = each.value.service_name
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    aws_route_table.public[*].id,
    aws_route_table.private[*].id,
    aws_route_table.database[*].id
  )

  tags = merge(var.tags, {
    Name = "${var.name}-vpce-${each.key}"
  })
}

# Interface VPC Endpoints
resource "aws_vpc_endpoint" "interface" {
  for_each = var.enable_vpc_endpoints ? {
    for k, v in merge(local.default_vpc_endpoints, var.vpc_endpoints) : k => v
    if v.vpc_endpoint_type == "Interface"
  } : {}

  vpc_id              = aws_vpc.this.id
  service_name        = each.value.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = each.value.private_dns_enabled
  subnet_ids          = local.vpc_endpoint_subnet_ids
  security_group_ids  = length(each.value.security_group_ids) > 0 ? each.value.security_group_ids : [aws_security_group.vpc_endpoints[0].id]

  tags = merge(var.tags, {
    Name = "${var.name}-vpce-${each.key}"
  })
}

# VPC Endpoint Security Group
resource "aws_security_group" "vpc_endpoints" {
  count = var.enable_vpc_endpoints && anytrue([for k, v in merge(local.default_vpc_endpoints, var.vpc_endpoints) : v.vpc_endpoint_type == "Interface"]) ? 1 : 0

  name_prefix = "${var.name}-vpce-"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-vpce-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}
