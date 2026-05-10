provider "aws" {
  region = var.aws_region
}


# Create VPC and pass in exactly the variables your module expects
module "vpc" {
  source = "./modules/vpc"

  name       = var.author_name
  cidr_block = var.cidr_block

  azs                      = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_subnet_cidrs     = var.private_subnet_cidrs
  database_subnet_cidrs    = var.database_subnet_cidrs
  elasticache_subnet_cidrs = var.elasticache_subnet_cidrs

  enable_nat_gateway     = true
  one_nat_gateway_per_az = true

  enable_flow_logs         = true
  flow_logs_retention_days = 30

  tags = {
    Environment  = var.environment
    Architecture = "3-tier"
  }
}

# ALB Security Group
module "alb_sg" {
  source = "./modules/security-group"

  name        = "alb-sg-${var.author_name}"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTP" },
    { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTPS" }
  ]
}

# Web Tier Security Group
module "web_sg" {
  source = "./modules/security-group"

  name        = "web-sg-${var.author_name}"
  description = "Security group for web servers"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    { from_port = 80, to_port = 80, protocol = "tcp", source_security_group_id = module.alb_sg.security_group_id, description = "HTTP from ALB" },
    { from_port = 443, to_port = 443, protocol = "tcp", source_security_group_id = module.alb_sg.security_group_id, description = "HTTPS from ALB" },
    { from_port = 8080, to_port = 8080, protocol = "tcp", source_security_group_id = module.web_sg.security_group_id, description = "App from web" },
    { from_port = 8081, to_port = 8081, protocol = "tcp", source_security_group_id = module.web_sg.security_group_id, description = "App from web" }

  ]
}

# Backend Security Group
module "backend_sg" {
  source = "./modules/security-group"

  name        = "backend-sg-${var.author_name}"
  description = "Security group for backend servers"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    { from_port = 6379, to_port = 6379, protocol = "tcp", source_security_group_id = module.web_sg.security_group_id, description = "Redis from app" }
  ]

  enable_default_egress = true
}

# Database Security Group
module "db_sg" {
  source = "./modules/security-group"

  name        = "db-sg-${var.author_name}"
  description = "Security group for databases"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    { from_port = 5432, to_port = 5432, protocol = "tcp", source_security_group_id = module.web_sg.security_group_id, description = "PostgreSQL from web" },
    { from_port = 5432, to_port = 5432, protocol = "tcp", source_security_group_id = module.backend_sg.security_group_id, description = "PostgreSQL from backend" }
  ]

  enable_default_egress = false
}

# Bastion Security Group
module "bastion_sg" {
  source = "./modules/security-group"

  name        = "bastion-sg-${var.author_name}"
  description = "Security group for bastion host"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description = "SSH from office"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.my_ip_cidr]
    }
  ]

  egress_rules = [
    {
      description              = "SSH to web"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = module.web_sg.security_group_id
    },
    {
      description              = "SSH to backend"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = module.backend_sg.security_group_id
    },
    {
      description              = "SSH to database"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = module.db_sg.security_group_id
    }
  ]

  enable_default_egress = false

  tags = {
    Environment = var.environment
    Tier        = "3-tier"
  }
}


# Create EKS cluster and pass in exactly the variables your module expects
module "eks" {
  source = "./modules/eks"

  cluster_name    = "${var.author_name}-eks-cluster"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  node_groups = {
    general = {
      instance_types = var.cluster_instance_type
      capacity_type  = "ON_DEMAND"
      min_size       = var.cluster_min_size
      max_size       = var.cluster_max_size
      desired_size   = var.cluster_desired_size
    }
  }

  tags = {
    Environment = var.environment
    Project     = "${var.author_name}-project"
  }
}


# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "docker_logs" {
  name              = "/aws/ec2/docker/all"
  retention_in_days = 7

  tags = {
    Name = "docker-logs-${var.author_name}"
  }
}

resource "aws_cloudwatch_log_group" "system_logs" {
  name              = "/aws/ec2/system/all"
  retention_in_days = 7

  tags = {
    Name = "system-logs-${var.author_name}"
  }
}


# CloudWatch IAM Role & Attach CloudWatch policy to role
module "cloudwatch_role" {
  source = "./modules/iam-role"

  name        = "ec2-cloudwatch-role-${var.author_name}"
  description = "IAM role for EC2 instances to send logs to CloudWatch"

  trusted_services = ["ec2.amazonaws.com"]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]

  create_instance_profile = true

  tags = {
    Name        = "ec2-cloudwatch-role-${var.author_name}"
    Author      = var.author_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}


# FRONTEND (Public) - One instance per AZ
resource "aws_instance" "frontend" {
  for_each = module.vpc.public_subnets

  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = each.value.id
  vpc_security_group_ids      = [module.web_sg.security_group_id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = true
  iam_instance_profile        = module.cloudwatch_role.instance_profile_name

  tags = {
    Name = "${var.ec2_instances["frontend"]}-${each.key}"
    AZ   = each.key
  }

  depends_on = [module.vpc]
}

# BACKEND (Private) - One instance per AZ
resource "aws_instance" "backend" {
  for_each = module.vpc.private_subnets

  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = each.value.id
  vpc_security_group_ids = [module.backend_sg.security_group_id]
  key_name               = var.key_pair_name
  iam_instance_profile   = module.cloudwatch_role.instance_profile_name

  tags = {
    Name = "${var.ec2_instances["backend"]}-${each.key}"
    AZ   = each.key
    Tier = "backend"
  }

  depends_on = [module.vpc]
}

# DATABASE (Private Database Subnets) - One instance per AZ
resource "aws_instance" "database" {
  for_each = module.vpc.database_subnets

  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = each.value.id
  vpc_security_group_ids = [module.db_sg.security_group_id]
  key_name               = var.key_pair_name
  iam_instance_profile   = module.cloudwatch_role.instance_profile_name

  tags = {
    Name = "${var.ec2_instances["database"]}-${each.key}"
    AZ   = each.key
    Tier = "database"
  }

  depends_on = [module.vpc]
}

# BASTION (Public) - One instance in first AZ
resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids      = [module.bastion_sg.security_group_id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = true
  iam_instance_profile        = module.cloudwatch_role.instance_profile_name

  tags = {
    Name = var.ec2_instances["bastion"]
    Tier = "management"
  }

  depends_on = [module.vpc]
}
