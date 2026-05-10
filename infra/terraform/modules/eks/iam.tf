# Data Sources
data "aws_partition" "current" {}


# Cluster IAM Role
module "cluster_role" {
  source = "../../modules/iam-role"
  count = var.cluster_role_arn == "" ? 1 : 0

  name        = "${var.cluster_name}-cluster-role"
  description = "IAM role for EKS cluster ${var.cluster_name}"
  trusted_services = ["eks.amazonaws.com"]

  managed_policy_arns = concat(
    [
      "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy",
      "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSVPCResourceController",
    ],
    var.cluster_policy_arns
  )

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-cluster-role"
  })
}


# Node IAM Role
module "node_role" {
  source = "../../modules/iam-role"
  count  = var.node_role_arn == "" ? 1 : 0

  name        = "${var.cluster_name}-node-role"
  description = "IAM role for EKS worker nodes ${var.cluster_name}"
  trusted_services = ["ec2.amazonaws.com"]

  managed_policy_arns = concat(
    [
      "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy",
      "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy",
      "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
      "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore",
    ],
    var.node_policy_arns
  )

  create_instance_profile = true

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-node-role"
  })
}


# OIDC Provider for IRSA
data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  count = var.cluster_role_arn == "" ? 1 : 0

  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-oidc"
  })
}


# Local Values for Role ARNs
locals {
  cluster_role_arn           = var.cluster_role_arn != "" ? var.cluster_role_arn : module.cluster_role[0].role_arn
  node_role_arn              = var.node_role_arn != "" ? var.node_role_arn : module.node_role[0].role_arn
  node_instance_profile_name = var.node_role_arn != "" ? "" : module.node_role[0].instance_profile_name
  oidc_provider_arn          = var.cluster_role_arn == "" ? aws_iam_openid_connect_provider.eks[0].arn : ""
  oidc_provider_url          = var.cluster_role_arn == "" ? replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "") : ""
}
