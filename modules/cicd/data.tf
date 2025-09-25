locals {
  tags = merge(var.tags, { STAGE = var.environment, COSTCENTER = var.namespace, PROJECT_NAME = var.namespace })
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Data source for current AWS region
data "aws_region" "current" {}