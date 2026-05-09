# Public Subnets
resource "aws_subnet" "public" {
  count = local.num_public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index % length(local.azs)]
  map_public_ip_on_launch = true

  tags = merge(var.tags, var.public_subnet_tags, {
    Name                                          = "${var.name}-public-${local.azs[count.index % length(local.azs)]}"
    Tier                                          = "public"
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${var.name}"    = "shared"
  })
}


# Private Subnets
resource "aws_subnet" "private" {
  count = local.num_private_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index % length(local.azs)]

  tags = merge(var.tags, var.private_subnet_tags, {
    Name                                          = "${var.name}-private-${local.azs[count.index % length(local.azs)]}"
    Tier                                          = "private"
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${var.name}"    = "shared"
  })
}


# Database Subnets
resource "aws_subnet" "database" {
  count = local.num_database_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index % length(local.azs)]

  tags = merge(var.tags, var.database_subnet_tags, {
    Name = "${var.name}-database-${local.azs[count.index % length(local.azs)]}"
    Tier = "database"
  })
}


# ElastiCache Subnets
resource "aws_subnet" "elasticache" {
  count = local.num_elasticache_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.elasticache_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index % length(local.azs)]

  tags = merge(var.tags, var.elasticache_subnet_tags, {
    Name = "${var.name}-elasticache-${local.azs[count.index % length(local.azs)]}"
    Tier = "elasticache"
  })
}


# Database Subnet Group
resource "aws_db_subnet_group" "this" {
  count = local.num_database_subnets > 0 ? 1 : 0

  name        = "${var.name}-database"
  description = "Database subnet group for ${var.name}"
  subnet_ids  = aws_subnet.database[*].id

  tags = merge(var.tags, {
    Name = "${var.name}-database"
  })
}

resource "aws_elasticache_subnet_group" "this" {
  count = local.num_elasticache_subnets > 0 ? 1 : 0

  name        = "${var.name}-elasticache"
  description = "ElastiCache subnet group for ${var.name}"
  subnet_ids  = aws_subnet.elasticache[*].id

  tags = merge(var.tags, {
    Name = "${var.name}-elasticache"
  })
}
