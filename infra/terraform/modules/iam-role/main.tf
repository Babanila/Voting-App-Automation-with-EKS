# IAM Role
resource "aws_iam_role" "this" {
  name                  = var.name
  description           = var.description
  path                  = var.path
  max_session_duration  = var.max_session_duration
  assume_role_policy    = local.assume_role_policy

  permissions_boundary = var.permissions_boundary_arn != "" ? var.permissions_boundary_arn : null

  tags = merge(var.tags, {
    Name      = var.name
    ManagedBy = "terraform"
  })
}


# Assume Role Policy
locals {
  assume_role_policy = var.assume_role_policy != "" ? var.assume_role_policy : data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  dynamic "statement" {
    for_each = var.trusted_entities

    content {
      effect = "Allow"

      principals {
        type        = statement.value.type
        identifiers = statement.value.identifiers
      }

      actions = ["sts:AssumeRole"]

      dynamic "condition" {
        for_each = statement.value.condition

        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}


# Managed Policy Attachments
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}


# Inline Policies
resource "aws_iam_role_policy" "inline" {
  for_each = var.inline_policies

  name   = each.value.name != "" ? each.value.name : each.key
  role   = aws_iam_role.this.id
  policy = each.value.policy
}


# Created Policies Attachment
resource "aws_iam_role_policy_attachment" "created" {
  for_each = {
    for k, v in var.policies : k => v
    if v.attach
  }

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this[each.key].arn
}


# Instance Profile
resource "aws_iam_instance_profile" "this" {
  count = var.create_instance_profile ? 1 : 0

  name = var.name
  role = aws_iam_role.this.name

  tags = var.tags
}
