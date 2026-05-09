# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = merge(var.tags, var.nat_gateway_tags, {
    Name = "${var.name}-nat-eip-${count.index}"
  })

  depends_on = [aws_internet_gateway.this]
}


# NAT Gateways
resource "aws_nat_gateway" "this" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index % local.num_public_subnets].id

  tags = merge(var.tags, var.nat_gateway_tags, {
    Name = "${var.name}-natgw-${count.index}"
  })

  depends_on = [aws_internet_gateway.this]
}

# Private Route Tables

resource "aws_route_table" "private" {
  count = local.num_private_subnets > 0 ? local.nat_gateway_count : 0

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-private-rt-${count.index}"
    Tier = "private"
  })
}

resource "aws_route" "private_nat" {
  count = local.num_private_subnets > 0 ? local.nat_gateway_count : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

resource "aws_route_table_association" "private" {
  count = local.num_private_subnets

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[
    var.single_nat_gateway ? 0 : count.index % local.nat_gateway_count
  ].id
}

# Database Route Tables

resource "aws_route_table" "database" {
  count = local.num_database_subnets > 0 && local.nat_gateway_count > 0 ? local.nat_gateway_count : 0

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-database-rt-${count.index}"
    Tier = "database"
  })
}

resource "aws_route" "database_nat" {
  count = local.num_database_subnets > 0 && local.nat_gateway_count > 0 ? local.nat_gateway_count : 0

  route_table_id         = aws_route_table.database[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

resource "aws_route_table_association" "database" {
  count = local.num_database_subnets > 0 && local.nat_gateway_count > 0 ? local.num_database_subnets : 0

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[
    var.single_nat_gateway ? 0 : count.index % local.nat_gateway_count
  ].id
}
