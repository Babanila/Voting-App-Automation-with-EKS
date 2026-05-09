# Usage Examples

## Basic: Web Server Security Group
module "web_sg" {
  source = "./modules/security-group"

  name        = "web-server-sg"
  description = "Security group for web servers"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description = "HTTP from anywhere"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTPS from anywhere"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = {
    Environment = "production"
    Purpose     = "web"
  }
}

output "web_sg_id" {
  value = module.web_sg.security_group_id
}


## Application Server Security Group
module "app_sg" {
  source = "./modules/security-group"

  name        = "app-server-sg"
  description = "Security group for application servers"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description    = "App port from web tier"
      from_port      = 8080
      to_port        = 8080
      protocol       = "tcp"
      security_groups = [module.web_sg.security_group_id]
    },
    {
      description = "SSH from bastion"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
    }
  ]

  tags = {
    Environment = "production"
    Purpose     = "app"
  }
}


## Database Security Group
module "db_sg" {
  source = "./modules/security-group"

  name        = "database-sg"
  description = "Security group for RDS databases"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description    = "PostgreSQL from app tier"
      from_port      = 5432
      to_port        = 5432
      protocol       = "tcp"
      security_groups = [module.app_sg.security_group_id]
    },
    {
      description    = "MySQL from app tier"
      from_port      = 3306
      to_port        = 3306
      protocol       = "tcp"
      security_groups = [module.app_sg.security_group_id]
    }
  ]

  enable_default_egress = false

  tags = {
    Environment = "production"
    Purpose     = "database"
  }
}


## Bastion Host Security Group
module "bastion_sg" {
  source = "./modules/security-group"

  name        = "bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description = "SSH from office IP"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["203.0.113.0/24"]  # Your office IP
    }
  ]

  egress_rules = [
    {
      description = "SSH to private subnets"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
    }
  ]

  enable_default_egress = false

  tags = {
    Environment = "production"
    Purpose     = "bastion"
  }
}


## EKS Cluster Security Groups
module "eks_cluster_sg" {
  source = "./modules/security-group"

  name        = "eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description = "HTTPS from anywhere"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = {
    Environment = "production"
    Service     = "eks"
    Component   = "cluster"
  }
}

module "eks_nodes_sg" {
  source = "./modules/security-group"

  name        = "eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description    = "Communication from cluster"
      from_port      = 1025
      to_port        = 65535
      protocol       = "tcp"
      security_groups = [module.eks_cluster_sg.security_group_id]
    },
    {
      description    = "HTTPS from cluster"
      from_port      = 443
      to_port        = 443
      protocol       = "tcp"
      security_groups = [module.eks_cluster_sg.security_group_id]
    },
    {
      description = "Node to node communication"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      self        = true
    }
  ]

  tags = {
    Environment = "production"
    Service     = "eks"
    Component   = "nodes"
  }
}


## ALB Security Group
module "alb_sg" {
  source = "./modules/security-group"

  name        = "alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description = "HTTP from internet"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTPS from internet"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  egress_rules = [
    {
      description    = "HTTP to app servers"
      from_port      = 8080
      to_port        = 8080
      protocol       = "tcp"
      security_groups = [module.app_sg.security_group_id]
    }
  ]

  enable_default_egress = false

  tags = {
    Environment = "production"
    Component   = "alb"
  }
}

## Redis Security Group
module "redis_sg" {
  source = "./modules/security-group"

  name        = "redis-sg"
  description = "Security group for Redis ElastiCache"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description    = "Redis from app tier"
      from_port      = 6379
      to_port        = 6379
      protocol       = "tcp"
      security_groups = [module.app_sg.security_group_id]
    }
  ]

  enable_default_egress = false

  tags = {
    Environment = "production"
    Service     = "elasticache"
  }
}


## RabbitMQ / AmazonMQ Security Group
module "mq_sg" {
  source = "./modules/security-group"

  name        = "rabbitmq-sg"
  description = "Security group for AmazonMQ RabbitMQ"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description    = "AMQP from app tier"
      from_port      = 5671
      to_port        = 5672
      protocol       = "tcp"
      security_groups = [module.app_sg.security_group_id]
    },
    {
      description    = "Management from bastion"
      from_port      = 5672
      to_port        = 5672
      protocol       = "tcp"
      security_groups = [module.bastion_sg.security_group_id]
    }
  ]

  tags = {
    Environment = "production"
    Service     = "amazonmq"
  }
}
