# IAM Role
resource "aws_iam_role" "this" {
  name                 = var.name
  description          = var.description
  path                 = var.path
  max_session_duration = var.max_session_duration
  assume_role_policy   = local.assume_role_policy

  permissions_boundary = var.permissions_boundary_arn != "" ? var.permissions_boundary_arn : null

  tags = merge(var.tags, {
    Name      = var.name
    ManagedBy = "terraform"
  })
}


# Assume Role Policy
locals {
  # Use custom policy if provided, otherwise generate from trusted entities
  assume_role_policy = var.assume_role_policy != "" ? var.assume_role_policy : data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  # Service principals
  dynamic "statement" {
    for_each = length(var.trusted_services) > 0 ? [1] : []

    content {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]

      principals {
        type        = "Service"
        identifiers = var.trusted_services
      }
    }
  }

  # ARN principals
  dynamic "statement" {
    for_each = length(var.trusted_arns) > 0 ? [1] : []

    content {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]

      principals {
        type        = "AWS"
        identifiers = var.trusted_arns
      }
    }
  }

  # Account principals
  dynamic "statement" {
    for_each = length(var.trusted_accounts) > 0 ? [1] : []

    content {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]

      principals {
        type        = "AWS"
        identifiers = [for account in var.trusted_accounts : "arn:aws:iam::${account}:root"]
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


# Created Policies
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
