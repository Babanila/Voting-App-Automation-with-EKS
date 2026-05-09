# Security Group
resource "aws_security_group" "this" {
  name        = var.name_prefix != "" ? null : var.name
  name_prefix = var.name_prefix != "" ? var.name_prefix : null
  description = var.description
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name      = var.name
    ManagedBy = "terraform"
  })

  lifecycle {
    create_before_destroy = true
  }
}


# Default Egress Rule (Allow All)
resource "aws_security_group_rule" "default_egress" {
  count = var.enable_default_egress ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = var.default_egress_cidr_blocks
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound traffic"
}
