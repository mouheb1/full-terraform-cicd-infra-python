# NEWS STACK - Development Environment
# Terraform configuration for newsaidemo.dev
# Uses separate backend-news module for simplicity

# Network infrastructure (VPC, subnets, etc.)
module "network" {
  source      = "../../../modules/network"
  environment = "dev"
  vpc_cidr    = "10.1.0.0/16"  # Different from geo (10.0.0.0/16)
  vpc_name    = "news-dev"
  namespace   = "news"

  tags = {
    namespace = "news"
  }
}

# Database (PostgreSQL with PostGIS)
module "database" {
  source = "../../../modules/database"

  namespace          = "news"
  environment        = "dev"
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  backend_security_group_id = module.backend.security_group_id

  db_username = var.db_username
  db_password = var.db_password

  tags = {
    namespace = "news"
  }
}

# S3 buckets for media storage
module "s3" {
  source = "../../../modules/s3"

  namespace   = "news"
  environment = "dev"
  vpc_id      = module.network.vpc_id

  private_subnet_ids        = module.network.private_subnet_ids
  backend_security_group_id = module.backend.security_group_id

  tags = {
    namespace = "news"
  }
}

# Backend infrastructure (EC2 with Docker) - NEWS SPECIFIC MODULE
module "backend" {
  source            = "../../../modules/backend-news"
  environment       = "dev"
  python_env        = "development"
  namespace         = "news"
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  instance_type     = "t3.small"
  key_name          = null

  # Database connection
  db_host     = module.database.database_endpoint
  db_port     = tostring(module.database.database_port)
  db_name     = module.database.database_name
  db_user     = var.db_username
  db_password = var.db_password

  # NEWS stack doesn't use Django or JWT
  django_secret_key = ""
  jwt_secret_key    = ""

  # Backend projects for NEWS stack
  backend_projects = [
    {
      name = "newsapp-backend"
      path = "/opt/news-backend"
    },
    {
      name = "newsapp-collector"
      path = "/opt/news-collector"
    },
    {
      name = "newsapp-agentic-ai"
      path = "/opt/news-agentic"
    }
  ]

  # S3 access policy
  s3_access_policy_arn = module.s3.s3_access_policy_arn

  tags = {
    namespace = "news"
  }
}

# CI/CD for newsapp-backend (Flask REST API) - Uses predefined CodeStar connection
module "news_backend_cicd" {
  source           = "../../../modules/cicd"
  environment      = "dev"
  namespace        = "news"
  backend_name     = "newsapp-backend"
  application_port = 5000

  github_owner  = "sabeel-it-consulting"
  github_repo   = "newsapp-backend"
  github_branch = "main"

  backend_instance_id        = module.backend.instance_id
  create_codestar_connection = false  # Use predefined connection
  codestar_connection_arn    = "arn:aws:codeconnections:us-east-1:299295683679:connection/dcb07804-8f74-4139-80a3-7a1459593f48"

  tags = {
    namespace = "news"
  }

  depends_on = [module.backend]
}

# CI/CD for newsapp-collector (RSS Feed Collector) - Uses predefined CodeStar connection
module "news_collector_cicd" {
  source           = "../../../modules/cicd"
  environment      = "dev"
  namespace        = "news"
  backend_name     = "newsapp-collector"
  application_port = 0  # Background service, no port

  github_owner  = "sabeel-it-consulting"
  github_repo   = "newsapp-collector"
  github_branch = "main"

  backend_instance_id        = module.backend.instance_id
  create_codestar_connection = false  # Use predefined connection
  codestar_connection_arn    = "arn:aws:codeconnections:us-east-1:299295683679:connection/dcb07804-8f74-4139-80a3-7a1459593f48"

  tags = {
    namespace = "news"
  }

  depends_on = [module.backend]
}

# CI/CD for newsapp-agentic-ai (AI Agent Service) - Uses predefined CodeStar connection
module "news_agentic_cicd" {
  source           = "../../../modules/cicd"
  environment      = "dev"
  namespace        = "news"
  backend_name     = "newsapp-agentic-ai"
  application_port = 0  # Background service, no port

  github_owner  = "sabeel-it-consulting"
  github_repo   = "newsapp-agentic-ai"
  github_branch = "main"

  backend_instance_id        = module.backend.instance_id
  create_codestar_connection = false  # Use predefined connection
  codestar_connection_arn    = "arn:aws:codeconnections:us-east-1:299295683679:connection/dcb07804-8f74-4139-80a3-7a1459593f48"

  tags = {
    namespace = "news"
  }

  depends_on = [module.backend]
}

# ACM Certificate and Route 53 for frontend domain
module "acm_certificate" {
  count  = var.enable_route53 && var.domain_name != "" ? 1 : 0
  source = "../../../modules/acm-certificate"

  domain_name        = var.domain_name
  backend_elastic_ip = module.backend.elastic_ip
  namespace          = "news"
  environment        = "dev"

  tags = {
    namespace = "news"
  }

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  depends_on = [module.backend]
}

# Frontend hosting (S3 + CloudFront)
module "news_frontend" {
  source      = "../../../modules/frontend"
  environment = "dev"
  namespace   = "news"

  create_route53_records = var.enable_route53 && var.domain_name != ""
  domain_name            = var.enable_route53 && var.domain_name != "" ? var.domain_name : ""
  certificate_arn        = var.enable_route53 && var.domain_name != "" ? module.acm_certificate[0].certificate_arn : ""
  hosted_zone_id         = var.enable_route53 && var.domain_name != "" ? module.acm_certificate[0].hosted_zone_id : ""

  tags = {
    namespace = "news"
    type      = "frontend"
  }

  depends_on = [module.acm_certificate]
}

# Frontend CI/CD pipeline
module "news_frontend_cicd" {
  source      = "../../../modules/frontend-cicd"
  environment = "dev"
  namespace   = "news"

  github_owner  = "sabeel-it-consulting"
  github_repo   = "newsapp-frontend"
  github_branch = "main"

  codestar_connection_arn = "arn:aws:codeconnections:us-east-1:299295683679:connection/dcb07804-8f74-4139-80a3-7a1459593f48"

  frontend_bucket_name        = module.news_frontend.frontend_bucket_name
  frontend_bucket_arn         = module.news_frontend.frontend_bucket_arn
  cloudfront_distribution_id  = module.news_frontend.cloudfront_distribution_id
  cloudfront_distribution_arn = module.news_frontend.cloudfront_distribution_arn

  backend_public_dns = module.backend.instance_public_dns
  backend_public_ip  = module.backend.elastic_ip
  api_domain         = var.enable_route53 && var.domain_name != "" ? "api.${var.domain_name}" : ""
  api1_domain        = var.enable_route53 && var.domain_name != "" ? "api1.${var.domain_name}" : ""
  api2_domain        = ""  # Not used
  api3_domain        = ""  # Not used

  tags = {
    namespace = "news"
    type      = "frontend-cicd"
  }

  depends_on = [module.backend, module.news_frontend]
}
