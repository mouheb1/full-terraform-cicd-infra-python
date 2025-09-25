locals {
  tags = merge(var.tags, { STAGE = var.environment, COSTCENTER = var.namespace, PROJECT_NAME = var.namespace })
}

data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
