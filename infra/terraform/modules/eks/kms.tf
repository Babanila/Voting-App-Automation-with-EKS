resource "aws_kms_key" "eks" {
  count = var.enable_envelope_encryption && var.kms_key_arn == "" ? 1 : 0

  description             = "KMS key for EKS cluster ${var.cluster_name} secrets encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-eks-kms"
  })
}

resource "aws_kms_alias" "eks" {
  count = var.enable_envelope_encryption && var.kms_key_arn == "" ? 1 : 0

  name          = "alias/eks-${var.cluster_name}"
  target_key_id = aws_kms_key.eks[0].key_id
}
