# Cluster Outputs
output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "The endpoint URL for the EKS cluster API server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_version" {
  description = "The Kubernetes version of the cluster"
  value       = aws_eks_cluster.this.version
}

output "cluster_certificate_authority" {
  description = "The base64 encoded certificate data"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = local.cluster_role_arn
}

output "cluster_oidc_issuer_url" {
  description = "The OIDC issuer URL"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "cluster_oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  value       = length(aws_iam_openid_connect_provider.eks) > 0 ? aws_iam_openid_connect_provider.eks[0].arn : ""
}


# Node Role Outputs
output "node_role_arn" {
  description = "IAM role ARN of the EKS nodes"
  value       = local.node_role_arn
}

output "node_instance_profile_name" {
  description = "Instance profile name of the EKS nodes"
  value       = local.node_instance_profile_name
}


# Node Group Outputs
output "node_groups" {
  description = "Map of node group attributes"
  value = {
    for k, v in aws_eks_node_group.this : k => {
      arn           = v.arn
      status        = v.status
      capacity_type = v.capacity_type
      scaling_config = v.scaling_config
    }
  }
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = aws_security_group.node.id
}


# OIDC Outputs
output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = length(aws_iam_openid_connect_provider.eks) > 0 ? aws_iam_openid_connect_provider.eks[0].arn : ""
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider"
  value       = length(aws_iam_openid_connect_provider.eks) > 0 ? replace(aws_iam_openid_connect_provider.eks[0].url, "https://", "") : ""
}
