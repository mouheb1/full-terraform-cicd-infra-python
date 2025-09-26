
# Shared infrastructure (network, EC2, database, S3)
module "shared_infrastructure" {
  source        = "../../../modules"
  environment   = "dev"
  python_env    = "development"
  namespace     = "geo"
  branch_name   = "main"
  vpc_cidr      = "10.0.0.0/16"
  vpc_name      = "geo-dev"
  instance_type = "t3.small"
  key_name      = null

  # Backend configuration for primary backend
  backend_name  = "geoinvestinsights-backend"  # Project-specific name for pipeline

  # GitHub configuration for primary backend
  github_owner  = "sabeel-it-consulting"
  github_repo   = "geoinvestinsights-backend"
  github_branch = "main"

  # Database configuration - passwords are in terraform.tfvars
  db_username = var.db_username
  db_password = var.db_password

  # Django configuration - secret key is in terraform.tfvars
  django_secret_key = var.django_secret_key

  profile = "geo"
  region  = "eu-west-3"
  tags = {
    namespace = "geo"
  }
}

# Additional CI/CD pipeline for second backend
module "geo_secondback_cicd" {
  source        = "../../../modules/cicd"
  environment   = "dev"
  namespace     = "geo"
  backend_name  = "geoinvestinsights-secondback"  # Project-specific name for pipeline
  application_port = 5000                          # Flask runs on port 5000

  github_owner  = "sabeel-it-consulting"
  github_repo   = "geoinvestinsights-secondback"
  github_branch = "main"

  # Use the same backend instance and CodeStar connection from shared infrastructure
  backend_instance_id     = module.shared_infrastructure.backend_instance_id
  codestar_connection_arn = module.shared_infrastructure.codestar_connection_arn

  tags = {
    namespace = "geo"
  }

  # Ensure shared infrastructure (including CodeStar connection) is created first
  depends_on = [module.shared_infrastructure]
}

# Additional CI/CD pipeline for third backend
module "geo_thirdback_cicd" {
  source        = "../../../modules/cicd"
  environment   = "dev"
  namespace     = "geo"
  backend_name  = "geoinvestinsights-thirdback"   # Project-specific name for pipeline
  application_port = 5001                          # Flask runs on port 5001

  github_owner  = "sabeel-it-consulting"
  github_repo   = "geoinvestinsights-thirdback"
  github_branch = "main"

  # Use the same backend instance and CodeStar connection from shared infrastructure
  backend_instance_id     = module.shared_infrastructure.backend_instance_id
  codestar_connection_arn = module.shared_infrastructure.codestar_connection_arn

  tags = {
    namespace = "geo"
  }

  # Ensure shared infrastructure (including CodeStar connection) is created first
  depends_on = [module.shared_infrastructure]
}

# Additional CI/CD pipeline for auth backend
module "geo_authback_cicd" {
  source        = "../../../modules/cicd"
  environment   = "dev"
  namespace     = "geo"
  backend_name  = "geoinvestinsights-authback"    # Project-specific name for pipeline
  application_port = 5002                          # Flask runs on port 5002

  github_owner  = "sabeel-it-consulting"
  github_repo   = "geoinvestinsights-authback"
  github_branch = "main"

  # Use the same backend instance and CodeStar connection from shared infrastructure
  backend_instance_id     = module.shared_infrastructure.backend_instance_id
  codestar_connection_arn = module.shared_infrastructure.codestar_connection_arn

  tags = {
    namespace = "geo"
  }

  # Ensure shared infrastructure (including CodeStar connection) is created first
  depends_on = [module.shared_infrastructure]
}

# Frontend hosting infrastructure (React app)
module "geo_frontend" {
  source      = "../../../modules/frontend"
  environment = "dev"
  namespace   = "geo"

  tags = {
    namespace = "geo"
    type      = "frontend"
  }
}

# Frontend CI/CD pipeline for React app
module "geo_frontend_cicd" {
  source      = "../../../modules/frontend-cicd"
  environment = "dev"
  namespace   = "geo"

  github_owner  = "sabeel-it-consulting"
  github_repo   = "geoinvestinsights-frontend"
  github_branch = "main"

  # Use the same CodeStar connection from shared infrastructure
  codestar_connection_arn = module.shared_infrastructure.codestar_connection_arn

  # Connect to the frontend hosting resources
  frontend_bucket_name        = module.geo_frontend.frontend_bucket_name
  frontend_bucket_arn         = module.geo_frontend.frontend_bucket_arn
  cloudfront_distribution_id  = module.geo_frontend.cloudfront_distribution_id
  cloudfront_distribution_arn = module.geo_frontend.cloudfront_distribution_arn

  # Backend endpoints for React app
  backend_public_dns = module.shared_infrastructure.backend_public_dns

  tags = {
    namespace = "geo"
    type      = "frontend-cicd"
  }

  # Ensure shared infrastructure and frontend hosting are created first
  depends_on = [module.shared_infrastructure, module.geo_frontend]
}
