# IAM Policies (created by this module)
resource "aws_iam_policy" "this" {
  for_each = var.policies

  name        = each.key
  description = each.value.description
  path        = each.value.path
  policy      = each.value.policy

  tags = merge(var.tags, {
    Name      = each.key
    ManagedBy = "terraform"
  })
}
