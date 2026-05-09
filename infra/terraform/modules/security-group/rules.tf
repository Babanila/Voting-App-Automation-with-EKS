# Ingress Rules
resource "aws_security_group_rule" "ingress" {
  for_each = { for idx, rule in var.ingress_rules : idx => rule }

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  ipv6_cidr_blocks  = each.value.ipv6_cidr_blocks
  security_groups   = each.value.security_groups
  self              = each.value.self
  prefix_list_ids   = each.value.prefix_list_ids
  security_group_id = aws_security_group.this.id
  description       = each.value.description != "" ? each.value.description : "Ingress rule ${each.key}"
}


# Egress Rules (Additional)
resource "aws_security_group_rule" "egress" {
  for_each = { for idx, rule in var.egress_rules : idx => rule }

  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  ipv6_cidr_blocks  = each.value.ipv6_cidr_blocks
  security_groups   = each.value.security_groups
  self              = each.value.self
  prefix_list_ids   = each.value.prefix_list_ids
  security_group_id = aws_security_group.this.id
  description       = each.value.description != "" ? each.value.description : "Egress rule ${each.key}"
}
