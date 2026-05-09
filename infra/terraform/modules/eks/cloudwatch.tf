# CloudWatch Log Group for EKS Cluster
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention_days

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-eks-logs"
  })
}
