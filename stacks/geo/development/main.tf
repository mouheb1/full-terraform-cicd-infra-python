
module "geo_environment" {
  source        = "../../../modules"
  environment   = "dev"
  python_env    = "development"
  namespace     = "geo"
  branch_name   = "main"
  vpc_cidr      = "10.0.0.0/16"
  vpc_name      = "geo-dev"
  instance_type = "t3.micro"
  key_name      = null

  # GitHub configuration
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
