
module "geo_environment" {
  source        = "../../../modules"
  environment   = "dev"
  node_env      = "development"
  namespace     = "geo"
  branch_name   = "main"
  vpc_cidr      = "10.0.0.0/16"
  vpc_name      = "geo-dev"
  instance_type = "t3.micro"
  key_name      = null

  # GitHub configuration
  github_owner  = "mouheb1"
  github_repo   = "nestjs-graphql-boilerplate"
  github_branch = "main"

  # Database configuration - passwords are in terraform.tfvars
  db_username = var.db_username
  db_password = var.db_password

  # JWT configuration - keys are in terraform.tfvars
  jwt_private_key               = var.jwt_private_key
  jwt_public_key                = var.jwt_public_key
  jwt_refresh_token_private_key = var.jwt_refresh_token_private_key

  profile = "geo"
  region  = "eu-west-3"
  tags = {
    namespace = "geo"
  }
}
