# General Configuration
variable "name" {
  description = "Name prefix for all VPC resources"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,99}$", var.name))
    error_message = "Name must start with a letter, contain only alphanumeric characters and hyphens."
  }
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "CIDR block must be a valid IPv4 CIDR."
  }
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks for the VPC"
  type        = list(string)
  default     = []
}

# Subnet Configuration
variable "azs" {
  description = "List of availability zones"
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2
    error_message = "At least 2 availability zones are required."
  }
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.public_subnet_cidrs) == 0 || length(var.public_subnet_cidrs) == length(var.azs)
    error_message = "Number of public subnet CIDRs must match number of AZs."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.private_subnet_cidrs) == 0 || length(var.private_subnet_cidrs) == length(var.azs)
    error_message = "Number of private subnet CIDRs must match number of AZs."
  }
}

variable "database_subnet_cidrs" {
  description = "List of CIDR blocks for database subnets"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.database_subnet_cidrs) == 0 || length(var.database_subnet_cidrs) == length(var.azs)
    error_message = "Number of database subnet CIDRs must match number of AZs."
  }
}

variable "elasticache_subnet_cidrs" {
  description = "List of CIDR blocks for ElastiCache subnets"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.elasticache_subnet_cidrs) == 0 || length(var.elasticache_subnet_cidrs) == length(var.azs)
    error_message = "Number of ElastiCache subnet CIDRs must match number of AZs."
  }
}

# NAT Gateway Configuration
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway(s) for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway instead of one per AZ"
  type        = bool
  default     = false
}

variable "one_nat_gateway_per_az" {
  description = "Use one NAT Gateway per AZ (overrides single_nat_gateway)"
  type        = bool
  default     = true
}

# VPC Flow Logs Configuration
variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "flow_logs_destination_type" {
  description = "Flow Logs destination type (cloud-watch-logs, s3)"
  type        = string
  default     = "cloud-watch-logs"

  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.flow_logs_destination_type)
    error_message = "Flow logs destination must be cloud-watch-logs or s3."
  }
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain flow logs in CloudWatch"
  type        = number
  default     = 30
}

variable "flow_logs_s3_bucket_arn" {
  description = "ARN of the S3 bucket for flow logs (required if destination is s3)"
  type        = string
  default     = ""
}

variable "flow_logs_max_aggregation_interval" {
  description = "Maximum aggregation interval in seconds for flow logs"
  type        = number
  default     = 60

  validation {
    condition     = contains([60, 600], var.flow_logs_max_aggregation_interval)
    error_message = "Aggregation interval must be 60 or 600 seconds."
  }
}

# VPC Endpoints Configuration
variable "enable_vpc_endpoints" {
  description = "Enable VPC endpoints"
  type        = bool
  default     = false
}

variable "vpc_endpoints" {
  description = "Map of VPC endpoints to create"
  type = map(object({
    service_name        = string
    vpc_endpoint_type   = optional(string, "Interface")
    private_dns_enabled = optional(bool, true)
    security_group_ids  = optional(list(string), [])
  }))
  default = {}
}

variable "vpc_endpoint_subnet_ids_type" {
  description = "Which subnet type to use for interface endpoints (private, database)"
  type        = string
  default     = "private"
}

# DHCP Options

variable "enable_dhcp_options" {
  description = "Enable custom DHCP options"
  type        = bool
  default     = false
}

variable "dhcp_options_domain_name" {
  description = "Domain name for DHCP options"
  type        = string
  default     = ""
}

variable "dhcp_options_domain_name_servers" {
  description = "Domain name servers for DHCP options"
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

variable "dhcp_options_ntp_servers" {
  description = "NTP servers for DHCP options"
  type        = list(string)
  default     = []
}

# Network ACLs
variable "public_dedicated_network_acl" {
  description = "Use dedicated network ACL for public subnets"
  type        = bool
  default     = false
}

variable "private_dedicated_network_acl" {
  description = "Use dedicated network ACL for private subnets"
  type        = bool
  default     = false
}

variable "database_dedicated_network_acl" {
  description = "Use dedicated network ACL for database subnets"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Additional tags for public subnets"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags for private subnets"
  type        = map(string)
  default     = {}
}

variable "database_subnet_tags" {
  description = "Additional tags for database subnets"
  type        = map(string)
  default     = {}
}

variable "elasticache_subnet_tags" {
  description = "Additional tags for ElastiCache subnets"
  type        = map(string)
  default     = {}
}

variable "nat_gateway_tags" {
  description = "Additional tags for NAT Gateways"
  type        = map(string)
  default     = {}
}

variable "igw_tags" {
  description = "Additional tags for Internet Gateway"
  type        = map(string)
  default     = {}
}
