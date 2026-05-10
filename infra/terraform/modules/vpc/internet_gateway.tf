# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, var.igw_tags, {
    Name = "${var.name}-igw"
  })
}


# Public Route Table
resource "aws_route_table" "public" {
  count = local.num_public_subnets > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
    Tier = "public"
  })
}

resource "aws_route" "public_internet" {
  count = local.num_public_subnets > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = local.num_public_subnets

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}
