locals {
  tags = merge(var.tags, { STAGE = var.environment, COSTCENTER = var.namespace, PROJECT_NAME = var.namespace })
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Random suffix for globally unique bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}