# Example Usages

## Basic: EC2 Role with S3 Access
module "ec2_role" {
  source = "./modules/iam-role"

  name        = "ec2-s3-access-role"
  description = "Role for EC2 instances to access S3"

  trusted_entities = [
    {
      type        = "service"
      identifiers = ["ec2.amazonaws.com"]
    }
  ]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  create_instance_profile = true

  tags = {
    Environment = "production"
    Purpose     = "s3-access"
  }
}

Outputs
output "role_arn" {
  value = module.ec2_role.role_arn
}

output "instance_profile_name" {
  value = module.ec2_role.instance_profile_name
}


## Lambda Role with Custom Policy
module "lambda_role" {
  source = "./modules/iam-role"

  name        = "lambda-execution-role"
  description = "Role for Lambda function execution"

  trusted_entities = [
    {
      type        = "service"
      identifiers = ["lambda.amazonaws.com"]
    }
  ]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]

  inline_policies = {
    "dynamodb-access" = {
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "dynamodb:GetItem",
              "dynamodb:PutItem",
              "dynamodb:UpdateItem",
              "dynamodb:DeleteItem",
              "dynamodb:Query"
            ]
            Resource = "arn:aws:dynamodb:us-east-1:123456789012:table/my-table"
          }
        ]
      })
    }
  }

  tags = {
    Environment = "production"
    Service     = "lambda"
  }
}

output "lambda_role_arn" {
  value = module.lambda_role.role_arn
}



## EKS Cluster Role
module "eks_cluster_role" {
  source = "./modules/iam-role"

  name        = "eks-cluster-role"
  description = "Role for EKS cluster"

  trusted_entities = [
    {
      type        = "service"
      identifiers = ["eks.amazonaws.com"]
    }
  ]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  ]

  tags = {
    Environment = "production"
    Service     = "eks"
  }
}

module "eks_node_role" {
  source = "./modules/iam-role"

  name        = "eks-node-role"
  description = "Role for EKS worker nodes"

  trusted_entities = [
    {
      type        = "service"
      identifiers = ["ec2.amazonaws.com"]
    }
  ]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  create_instance_profile = true

  tags = {
    Environment = "production"
    Service     = "eks"
  }
}


## Custom Policy with Created Policy
module "app_role" {
  source = "./modules/iam-role"

  name        = "my-application-role"
  description = "Role for my application with custom policies"

  trusted_entities = [
    {
      type        = "service"
      identifiers = ["ec2.amazonaws.com"]
    }
  ]

  # Create and attach policies
  policies = {
    "s3-full-access" = {
      description = "Full S3 access"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect   = "Allow"
            Action   = "s3:*"
            Resource = "*"
          }
        ]
      })
      attach = true
    }

    "dynamodb-read" = {
      description = "DynamoDB read-only access"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "dynamodb:GetItem",
              "dynamodb:BatchGetItem",
              "dynamodb:Query",
              "dynamodb:Scan"
            ]
            Resource = "*"
          }
        ]
      })
      attach = true
    }

    "cloudwatch-logs" = {
      description = "CloudWatch logs access"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents",
              "logs:DescribeLogStreams"
            ]
            Resource = "arn:aws:logs:*:*:*"
          }
        ]
      })
      attach = true
    }
  }

  create_instance_profile = true

  tags = {
    Environment = "production"
    Application = "my-app"
  }
}

output "app_role_arn" {
  value = module.app_role.role_arn
}

output "app_policy_arns" {
  value = module.app_role.policy_arns
}


## Cross-Account Access
module "cross_account_role" {
  source = "./modules/iam-role"

  name        = "cross-account-access-role"
  description = "Role for cross-account access"

  trusted_entities = [
    {
      type        = "account"
      identifiers = ["987654321098"]  # Trusted account ID
      condition = [
        {
          test     = "StringEquals"
          variable = "sts:ExternalId"
          values   = ["unique-external-id-123"]
        }
      ]
    }
  ]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ]

  max_session_duration = 7200  # 2 hours

  tags = {
    Environment  = "production"
    AccessType   = "cross-account"
    TrustedAccount = "987654321098"
  }
}

output "cross_account_role_arn" {
  value = module.cross_account_role.role_arn
}


## OIDC Federated Role (GitHub Actions, IRSA)
# GitHub Actions OIDC Role
module "github_actions_role" {
  source = "./modules/iam-role"

  name        = "github-actions-deploy-role"
  description = "Role for GitHub Actions to deploy to AWS"

  trusted_entities = [
    {
      type        = "federated"
      identifiers = ["arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"]
      condition = [
        {
          test     = "StringEquals"
          variable = "token.actions.githubusercontent.com:aud"
          values   = ["sts.amazonaws.com"]
        },
        {
          test     = "StringLike"
          variable = "token.actions.githubusercontent.com:sub"
          values   = ["repo:my-org/my-repo:ref:refs/heads/main"]
        }
      ]
    }
  ]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  ]

  inline_policies = {
    "s3-deploy" = {
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect   = "Allow"
            Action   = ["s3:*"]
            Resource = "arn:aws:s3:::my-deploy-bucket/*"
          }
        ]
      })
    }
  }

  tags = {
    Environment = "production"
    Purpose     = "ci-cd"
    Provider    = "github-actions"
  }
}

# EKS IRSA Role
module "irsa_role" {
  source = "./modules/iam-role"

  name        = "my-app-irsa-role"
  description = "IRSA role for my application"

  trusted_entities = [
    {
      type        = "federated"
      identifiers = ["arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"]
      condition = [
        {
          test     = "StringEquals"
          variable = "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE:sub"
          values   = ["system:serviceaccount:default:my-app-sa"]
        },
        {
          test     = "StringEquals"
          variable = "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE:aud"
          values   = ["sts.amazonaws.com"]
        }
      ]
    }
  ]

  inline_policies = {
    "app-permissions" = {
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "s3:GetObject",
              "s3:PutObject"
            ]
            Resource = "arn:aws:s3:::my-bucket/*"
          }
        ]
      })
    }
  }

  tags = {
    Environment = "production"
    Service     = "eks"
    Purpose     = "irsa"
  }
}


## Multiple Roles with ForEach
locals {
  roles = {
    "read-only" = {
      description = "Read-only access role"
      managed_policies = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess"
      ]
      trusted_services = ["ec2.amazonaws.com"]
    }
    "developer" = {
      description = "Developer access role"
      managed_policies = [
        "arn:aws:iam::aws:policy/PowerUserAccess"
      ]
      trusted_services = ["ec2.amazonaws.com"]
    }
    "admin" = {
      description = "Admin access role"
      managed_policies = [
        "arn:aws:iam::aws:policy/AdministratorAccess"
      ]
      trusted_services = ["ec2.amazonaws.com"]
    }
  }
}

module "roles" {
  source = "./modules/iam-role"

  for_each = local.roles

  name        = "${var.project}-${each.key}-role"
  description = each.value.description

  trusted_entities = [
    {
      type        = "service"
      identifiers = each.value.trusted_services
    }
  ]

  managed_policy_arns = each.value.managed_policies

  create_instance_profile = true

  tags = {
    Environment = var.environment
    Role        = each.key
  }
}

output "all_role_arns" {
  value = { for k, v in module.roles : k => v.role_arn }
}

output "all_instance_profile_names" {
  value = { for k, v in module.roles : k => v.instance_profile_name }
}


## Complete Example with SSM Access
module "bastion_role" {
  source = "./modules/iam-role"

  name        = "bastion-host-role"
  description = "Role for bastion host with SSM access"

  trusted_entities = [
    {
      type        = "service"
      identifiers = ["ec2.amazonaws.com"]
    }
  ]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
  ]

  inline_policies = {
    "cloudwatch-logs" = {
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents",
              "logs:DescribeLogStreams"
            ]
            Resource = "arn:aws:logs:*:*:*"
          }
        ]
      })
    }
  }

  create_instance_profile    = true
  permissions_boundary_arn   = "arn:aws:iam::aws:policy/PowerUserAccess"

  tags = {
    Environment = "production"
    Purpose     = "bastion"
  }
}


## Custom Assume Role Policy
module "custom_role" {
  source = "./modules/iam-role"

  name        = "custom-assume-role"
  description = "Role with custom assume role policy"

  # Override the trusted_entities with a custom policy
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::987654321098:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "my-secret-id"
          }
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  tags = {
    Environment = "production"
    Type        = "custom"
  }
}
