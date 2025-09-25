module "network" {
  source      = "./network"
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  vpc_name    = var.vpc_name
  tags        = var.tags
  namespace   = var.namespace
}

module "backend" {
  source            = "./backend"
  environment       = var.environment
  node_env          = var.node_env
  namespace         = var.namespace
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  instance_type     = var.instance_type
  key_name          = var.key_name
  tags              = var.tags

  # Database connection variables
  db_host     = module.database.database_endpoint
  db_port     = tostring(module.database.database_port)
  db_name     = module.database.database_name
  db_user     = var.db_username
  db_password = var.db_password

  # JWT configuration variables
  jwt_private_key               = var.jwt_private_key
  jwt_public_key                = var.jwt_public_key
  jwt_refresh_token_private_key = var.jwt_refresh_token_private_key

  # S3 access policy
  s3_access_policy_arn = module.s3.s3_access_policy_arn
}

module "cicd" {
  source        = "./cicd"
  environment   = var.environment
  namespace     = var.namespace
  github_owner  = var.github_owner
  github_repo   = var.github_repo
  github_branch = var.github_branch
  # github_token is no longer needed with CodeStar Connection
  backend_instance_id = module.backend.instance_id
  tags                = var.tags
}

# Add this to your main module file
module "database" {
  source = "./database"

  namespace          = var.namespace
  environment        = var.environment
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  backend_security_group_id = module.backend.security_group_id

  db_username = var.db_username
  db_password = var.db_password

  tags = local.tags
}

module "s3" {
  source = "./s3"

  namespace   = var.namespace
  environment = var.environment
  vpc_id      = module.network.vpc_id

  private_subnet_ids        = module.network.private_subnet_ids
  backend_security_group_id = module.backend.security_group_id

  tags = local.tags
}
