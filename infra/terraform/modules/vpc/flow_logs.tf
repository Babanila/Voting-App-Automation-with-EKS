# VPC Flow Logs
# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count = var.enable_flow_logs && var.flow_logs_destination_type == "cloud-watch-logs" ? 1 : 0

  name              = "/aws/vpc/flow-logs/${var.name}"
  retention_in_days = var.flow_logs_retention_days

  tags = merge(var.tags, {
    Name = "${var.name}-flow-logs"
  })
}

# IAM Role for Flow Logs
resource "aws_iam_role" "vpc_flow_logs" {
  count = var.enable_flow_logs && var.flow_logs_destination_type == "cloud-watch-logs" ? 1 : 0

  name = "${var.name}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Flow Logs
resource "aws_iam_role_policy" "vpc_flow_logs" {
  count = var.enable_flow_logs && var.flow_logs_destination_type == "cloud-watch-logs" ? 1 : 0

  name = "${var.name}-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Flow Log - CloudWatch
resource "aws_flow_log" "cloudwatch" {
  count = var.enable_flow_logs && var.flow_logs_destination_type == "cloud-watch-logs" ? 1 : 0

  vpc_id                   = aws_vpc.this.id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  iam_role_arn             = aws_iam_role.vpc_flow_logs[0].arn
  max_aggregation_interval = var.flow_logs_max_aggregation_interval

  tags = merge(var.tags, {
    Name = "${var.name}-flow-logs"
  })
}

# Flow Log - S3
resource "aws_flow_log" "s3" {
  count = var.enable_flow_logs && var.flow_logs_destination_type == "s3" ? 1 : 0

  vpc_id                   = aws_vpc.this.id
  traffic_type             = "ALL"
  log_destination_type     = "s3"
  log_destination          = var.flow_logs_s3_bucket_arn
  max_aggregation_interval = var.flow_logs_max_aggregation_interval

  tags = merge(var.tags, {
    Name = "${var.name}-flow-logs"
  })
}
