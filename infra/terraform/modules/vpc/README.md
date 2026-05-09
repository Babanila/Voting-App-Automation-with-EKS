# Example Usage


## Basic VPC
module "vpc" {
  source = "./modules/vpc"

  name = "my-vpc"
  cidr_block = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}

output "vpc_id" {
  value = module.vpc.vpc_id
}


## VPC for EKS
module "vpc" {
  source = "./modules/vpc"

  name = "my-eks-vpc"
  cidr_block = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  enable_nat_gateway     = true
  one_nat_gateway_per_az = true

  # EKS-specific subnet tags
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Environment = "production"
    Cluster     = "my-eks-cluster"
  }
}

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



## Complete VPC with All Features
module "vpc" {
  source = "./modules/vpc"

  name       = "my-production-vpc"
  cidr_block = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  elasticache_subnet_cidrs = ["10.0.31.0/24", "10.0.32.0/24", "10.0.33.0/24"]

  # NAT Gateway
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  # DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Flow Logs
  enable_flow_logs                = true
  flow_logs_destination_type      = "cloud-watch-logs"
  flow_logs_retention_days        = 30
  flow_logs_max_aggregation_interval = 60

  # VPC Endpoints
  enable_vpc_endpoints = true
  vpc_endpoints = {
    s3 = {
      service_name      = "com.amazonaws.us-east-1.s3"
      vpc_endpoint_type = "Gateway"
    }
    ecr_api = {
      service_name        = "com.amazonaws.us-east-1.ecr.api"
      vpc_endpoint_type   = "Interface"
      private_dns_enabled = true
    }
    ecr_dkr = {
      service_name        = "com.amazonaws.us-east-1.ecr.dkr"
      vpc_endpoint_type   = "Interface"
      private_dns_enabled = true
    }
    logs = {
      service_name        = "com.amazonaws.us-east-1.logs"
      vpc_endpoint_type   = "Interface"
      private_dns_enabled = true
    }
    sts = {
      service_name        = "com.amazonaws.us-east-1.sts"
      vpc_endpoint_type   = "Interface"
      private_dns_enabled = true
    }
  }

  # DHCP Options
  enable_dhcp_options      = true
  dhcp_options_domain_name = "example.com"
  dhcp_options_domain_name_servers = ["169.254.169.253", "8.8.8.8"]

  tags = {
    Environment = "production"
    Project     = "my-project"
    Terraform   = "true"
  }
}

# Outputs
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


## Single NAT Gateway (Cost-Saving)
module "vpc" {
  source = "./modules/vpc"

  name       = "my-dev-vpc"
  cidr_block = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  # Cost-saving: single NAT Gateway
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  tags = {
    Environment = "development"
  }
}



## VPC with Secondary CIDR
module "vpc" {
  source = "./modules/vpc"

  name       = "my-vpc"
  cidr_block = "10.0.0.0/16"

  secondary_cidr_blocks = ["10.1.0.0/16", "10.2.0.0/16"]

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  database_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]

  enable_nat_gateway = true

  tags = {
    Environment = "production"
  }
}


## VPC with VPC Flow Logs to S3
resource "aws_s3_bucket" "flow_logs" {
  bucket = "my-vpc-flow-logs"
}

module "vpc" {
  source = "./modules/vpc"

  name       = "my-vpc"
  cidr_block = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  enable_flow_logs                = true
  flow_logs_destination_type      = "s3"
  flow_logs_s3_bucket_arn         = aws_s3_bucket.flow_logs.arn
  flow_logs_max_aggregation_interval = 60

  tags = {
    Environment = "production"
  }
}
