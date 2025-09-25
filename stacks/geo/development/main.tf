
# Shared infrastructure (network, EC2, database, S3)
module "shared_infrastructure" {
  source        = "../../../modules"
  environment   = "dev"
  python_env    = "development"
  namespace     = "geo"
  branch_name   = "main"
  vpc_cidr      = "10.0.0.0/16"
  vpc_name      = "geo-dev"
  instance_type = "t3.micro"
  key_name      = null

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
  backend_name  = "secondback"  # Unique identifier for this backend
  application_port = 5000       # Flask runs on port 5000

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
