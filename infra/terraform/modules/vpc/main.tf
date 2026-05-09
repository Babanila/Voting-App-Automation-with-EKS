# Data Sources
data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(var.tags, {
    Name = var.name
  })
}

# VPC CIDR Associations
resource "aws_vpc_ipv4_cidr_block_association" "secondary" {
  for_each = toset(var.secondary_cidr_blocks)

  vpc_id     = aws_vpc.this.id
  cidr_block = each.value
}

# DHCP Options
resource "aws_vpc_dhcp_options" "this" {
  count = var.enable_dhcp_options ? 1 : 0

  domain_name          = var.dhcp_options_domain_name != "" ? var.dhcp_options_domain_name : null
  domain_name_servers  = var.dhcp_options_domain_name_servers
  ntp_servers          = length(var.dhcp_options_ntp_servers) > 0 ? var.dhcp_options_ntp_servers : null

  tags = merge(var.tags, {
    Name = "${var.name}-dhcp-options"
  })
}

resource "aws_vpc_dhcp_options_association" "this" {
  count = var.enable_dhcp_options ? 1 : 0

  vpc_id          = aws_vpc.this.id
  dhcp_options_id = aws_vpc_dhcp_options.this[0].id
}

# Local Values
locals {
  azs = length(var.azs) > 0 ? var.azs : slice(data.aws_availability_zones.available.names, 0, 3)

  num_public_subnets   = length(var.public_subnet_cidrs)
  num_private_subnets  = length(var.private_subnet_cidrs)
  num_database_subnets = length(var.database_subnet_cidrs)
  num_elasticache_subnets = length(var.elasticache_subnet_cidrs)

  # NAT Gateway count
  nat_gateway_count = var.enable_nat_gateway ? (
    var.single_nat_gateway ? 1 : (
      var.one_nat_gateway_per_az ? length(local.azs) : 1
    )
  ) : 0

  common_tags = merge(var.tags, {
    VPC = var.name
  })
}
