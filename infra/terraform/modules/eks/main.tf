# EKS Cluster
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = local.cluster_role_arn

  enabled_cluster_log_types = var.cluster_log_types

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
    security_group_ids      = [aws_security_group.cluster.id]
  }

  dynamic "encryption_config" {
    for_each = var.enable_envelope_encryption ? [1] : []

    content {
      provider {
        key_arn = var.kms_key_arn != "" ? var.kms_key_arn : aws_kms_key.eks[0].arn
      }
      resources = ["secrets"]
    }
  }

  tags = merge(var.tags, var.cluster_tags, {
    Name = var.cluster_name
  })

  depends_on = [
    aws_cloudwatch_log_group.eks,
    module.cluster_role,
  ]
}
