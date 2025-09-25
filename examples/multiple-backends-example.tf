# Example: Multiple Backend Configuration
# This example shows how to create multiple Python backends on the same EC2 instance
# without resource duplication conflicts

# Shared infrastructure (network, EC2, database, S3) - CREATE ONCE
module "shared_infrastructure" {
  source        = "../modules"
  environment   = "dev"
  python_env    = "development"
  namespace     = "geo"
  branch_name   = "main"
  vpc_cidr      = "10.0.0.0/16"
  vpc_name      = "geo-dev"
  instance_type = "t3.micro"
  key_name      = null

  # GitHub configuration for primary backend (Django)
  github_owner  = "sabeel-it-consulting"
  github_repo   = "geoinvestinsights-backend"
  github_branch = "main"

  # Database configuration - shared across all backends
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

# Backend 2: Flask API for Reports (geoinvestinsights-secondback)
module "geo_secondback_cicd" {
  source        = "../modules/cicd"
  environment   = "dev"
  namespace     = "geo"
  backend_name  = "secondback"     # Unique name - prevents resource conflicts
  application_port = 5000          # Flask port - different from Django
  
  github_owner  = "sabeel-it-consulting"
  github_repo   = "geoinvestinsights-secondback"
  github_branch = "main"

  # IMPORTANT: Reuse shared resources
  backend_instance_id = module.shared_infrastructure.backend_instance_id
  codestar_connection_arn = module.shared_infrastructure.codestar_connection_arn

  tags = {
    namespace = "geo"
    backend = "secondback"
  }
}

# Backend 3: Example - Data Processing Service (FastAPI)
module "geo_dataprocessing_cicd" {
  source        = "../modules/cicd"
  environment   = "dev"
  namespace     = "geo"
  backend_name  = "dataprocessing"  # Another unique name
  application_port = 8080           # FastAPI port - different from others
  
  github_owner  = "sabeel-it-consulting"
  github_repo   = "geoinvestinsights-dataprocessing"
  github_branch = "main"

  # IMPORTANT: Reuse shared resources
  backend_instance_id = module.shared_infrastructure.backend_instance_id
  codestar_connection_arn = module.shared_infrastructure.codestar_connection_arn

  tags = {
    namespace = "geo"
    backend = "dataprocessing"
  }
}

# Backend 4: Example - Real-time Analytics (WebSocket service)
module "geo_analytics_cicd" {
  source        = "../modules/cicd"
  environment   = "dev"
  namespace     = "geo"
  backend_name  = "analytics"      # Unique name
  application_port = 3000          # Node.js/WebSocket port
  
  github_owner  = "sabeel-it-consulting"
  github_repo   = "geoinvestinsights-analytics"
  github_branch = "main"

  # IMPORTANT: Reuse shared resources
  backend_instance_id = module.shared_infrastructure.backend_instance_id
  codestar_connection_arn = module.shared_infrastructure.codestar_connection_arn

  tags = {
    namespace = "geo"
    backend = "analytics"
  }
}

# Output individual backend information
output "backends_info" {
  description = "Information about all deployed backends"
  value = {
    shared_infrastructure = {
      vpc_id            = module.shared_infrastructure.vpc_id
      instance_id       = module.shared_infrastructure.backend_instance_id
      instance_ip       = module.shared_infrastructure.backend_public_ip
      database_endpoint = module.shared_infrastructure.database_endpoint
    }
    
    primary_backend = {
      name         = "backend"
      port         = 8000
      type         = "Django"
      ecr_url      = module.shared_infrastructure.ecr_repository_url
      pipeline     = module.shared_infrastructure.codepipeline_name
    }
    
    secondary_backend = {
      name         = "secondback"
      port         = 5000
      type         = "Flask"
      ecr_url      = module.geo_secondback_cicd.ecr_repository_url
      pipeline     = module.geo_secondback_cicd.codepipeline_name
    }
    
    data_processing_backend = {
      name         = "dataprocessing"
      port         = 8080
      type         = "FastAPI"
      ecr_url      = module.geo_dataprocessing_cicd.ecr_repository_url
      pipeline     = module.geo_dataprocessing_cicd.codepipeline_name
    }
    
    analytics_backend = {
      name         = "analytics"
      port         = 3000
      type         = "Node.js/WebSocket"
      ecr_url      = module.geo_analytics_cicd.ecr_repository_url
      pipeline     = module.geo_analytics_cicd.codepipeline_name
    }
  }
}