locals {
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 3, k + 3)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 3, k)]
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    managed-by = "terraform"
    env        = var.env
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs                   = local.azs
  public_subnets        = local.public_subnets
  private_subnets       = local.private_subnets
  public_subnet_suffix  = "SubnetPublic"
  private_subnet_suffix = "SubnetPrivate"

  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true
  single_nat_gateway   = true

  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${var.vpc_name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${var.vpc_name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${var.vpc_name}-default" }

  public_subnet_tags = merge(local.tags, {
    "kubernetes.io/role/elb" = "1"
  })
  private_subnet_tags = merge(local.tags, {
    "karpenter.sh/discovery"          = var.vpc_name
    "kubernetes.io/role/internal-elb" = "1"
  })

  tags = local.tags
}

# CloudWatch Log Group for VPC Flow Logs
# resource "aws_cloudwatch_log_group" "vpc_flow_log" {
#   name              = "/aws/vpc-flow-log/${var.vpc_name}"
#   retention_in_days = 30

#   tags = {
#     Name = "${var.vpc_name}-flow-logs"
#   }
# }

# IAM Role for VPC Flow Logs
# resource "aws_iam_role" "vpc_flow_log_role" {
#   name = "${var.vpc_name}-flow-log-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Service = "vpc-flow-logs.amazonaws.com"
#       }
#       Action = "sts:AssumeRole"
#     }]
#   })

#   tags = {
#     Name = "${var.vpc_name}-flow-log-role"
#   }
# }

# IAM Role Policy for VPC Flow Logs
# resource "aws_iam_role_policy" "vpc_flow_log_policy" {
#   name = "${var.vpc_name}-flow-log-policy"
#   role = aws_iam_role.vpc_flow_log_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Action = [
#         "logs:CreateLogGroup",
#         "logs:CreateLogStream",
#         "logs:PutLogEvents",
#         "logs:DescribeLogGroups",
#         "logs:DescribeLogStreams"
#       ]
#       Resource = [
#         "${aws_cloudwatch_log_group.vpc_flow_log.arn}",
#         "${aws_cloudwatch_log_group.vpc_flow_log.arn}:*"
#       ]
#     }]
#   })
# }

# VPC Flow Log
# resource "aws_flow_log" "vpc_flow_log" {
#   iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
#   log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
#   traffic_type    = "ALL"
#   vpc_id          = module.vpc.vpc_id

#   tags = {
#     Name = "${var.vpc_name}-flow-log"
#   }
# }
