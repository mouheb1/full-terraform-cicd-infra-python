# Infrastructure outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.shared_infrastructure.vpc_id
}

output "backend_public_ip" {
  description = "Public IP address of the backend EC2 instance (original, changes on restart)"
  value       = module.shared_infrastructure.backend_public_ip
}

output "backend_elastic_ip" {
  description = "Static Elastic IP address of the backend EC2 instance - USE THIS FOR API CALLS"
  value       = module.shared_infrastructure.backend_elastic_ip
}

output "backend_public_dns" {
  description = "Public DNS name of the backend EC2 instance"
  value       = module.shared_infrastructure.backend_public_dns
}

# Database outputs
output "database_endpoint" {
  description = "Database endpoint"
  value       = module.shared_infrastructure.database_endpoint
}

output "database_port" {
  description = "Database port"
  value       = module.shared_infrastructure.database_port
}

output "database_name" {
  description = "Database name"
  value       = module.shared_infrastructure.database_name
}

# SSH Connection outputs
output "ssh_private_key_path" {
  description = "Path to the generated SSH private key"
  value       = module.shared_infrastructure.ssh_private_key_path
}

output "ssh_connection_command" {
  description = "SSH command to connect to the EC2 instance"
  value       = module.shared_infrastructure.ssh_connection_command
}

output "ssh_tunnel_command" {
  description = "SSH tunnel command for database access"
  value       = module.shared_infrastructure.ssh_tunnel_command
  sensitive   = true
}

# CI/CD outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository (primary backend)"
  value       = module.shared_infrastructure.ecr_repository_url
}

output "codepipeline_name" {
  description = "Name of the CodePipeline (primary backend)"
  value       = module.shared_infrastructure.codepipeline_name
}

# Additional backend CI/CD outputs
output "geo_secondback_ecr_repository_url" {
  description = "URL of the ECR repository for second backend"
  value       = module.geo_secondback_cicd.ecr_repository_url
}

output "geo_secondback_codepipeline_name" {
  description = "Name of the CodePipeline for second backend"
  value       = module.geo_secondback_cicd.codepipeline_name
}

# Frontend outputs
output "frontend_website_url" {
  description = "URL of the React application"
  value       = module.geo_frontend.website_url
}

output "frontend_cloudfront_domain" {
  description = "CloudFront domain name for the React app"
  value       = module.geo_frontend.cloudfront_domain_name
}

output "frontend_codepipeline_name" {
  description = "CodePipeline name for the React app"
  value       = module.geo_frontend_cicd.codepipeline_name
}

# DNS outputs (conditional)
output "nameservers" {
  description = "Route 53 nameservers to configure for your domain registrar"
  value       = var.enable_route53 && var.domain_name != "" ? module.acm_certificate[0].nameservers : []
}

output "hosted_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = var.enable_route53 && var.domain_name != "" ? module.acm_certificate[0].hosted_zone_id : ""
}

output "certificate_arn" {
  description = "ARN of the ACM certificate for CloudFront"
  value       = var.enable_route53 && var.domain_name != "" ? module.acm_certificate[0].certificate_arn : ""
}

output "frontend_domain" {
  description = "Custom domain for the frontend"
  value       = var.enable_route53 && var.domain_name != "" ? var.domain_name : ""
}

# Combined domain URLs for easy access
output "application_urls" {
  description = "All application URLs"
  value = {
    frontend_cloudfront = module.geo_frontend.website_url
    frontend_custom     = var.enable_route53 && var.domain_name != "" ? "https://${var.domain_name}" : "Not configured"
    backend_elastic_ip  = "http://${module.shared_infrastructure.backend_elastic_ip}:5002"
    backend_note        = "Frontend should call backend APIs using Elastic IP directly (no DNS)"
  }
}