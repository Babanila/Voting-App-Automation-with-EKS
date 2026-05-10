# Module EKS Basic Usage

## EKS Cluster
module "eks" {
  source = "./modules/eks"

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  node_groups = {
    general = {
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
      min_size       = 2
      max_size       = 5
      desired_size   = 3
    }
  }

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}


## IRSA Example - Create a role for a service account
module "app_irsa_role" {
  source = "./modules/iam-role"

  name        = "my-app-irsa-role"
  description = "IRSA role for my application"

  trusted_entities = [
    {
      type        = "federated"
      identifiers = [module.eks.oidc_provider_arn]
      condition = [
        {
          test     = "StringEquals"
          variable = "${module.eks.oidc_provider_url}:sub"
          values   = ["system:serviceaccount:default:my-app-sa"]
        },
        {
          test     = "StringEquals"
          variable = "${module.eks.oidc_provider_url}:aud"
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
  }
}



# Outputs
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "app_irsa_role_arn" {
  value = module.app_irsa_role.role_arn
}
