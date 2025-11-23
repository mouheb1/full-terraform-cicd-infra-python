# Infrastructure outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "backend_public_ip" {
  description = "Public IP address of the backend EC2 instance (original, changes on restart)"
  value       = module.backend.instance_public_ip
}

output "backend_elastic_ip" {
  description = "Static Elastic IP address of the backend EC2 instance - USE THIS FOR API CALLS"
  value       = module.backend.elastic_ip
}

output "backend_public_dns" {
  description = "Public DNS name of the backend EC2 instance"
  value       = module.backend.instance_public_dns
}

# Database outputs
output "database_endpoint" {
  description = "Database endpoint"
  value       = module.database.database_endpoint
}

output "database_port" {
  description = "Database port"
  value       = module.database.database_port
}

output "database_name" {
  description = "Database name"
  value       = module.database.database_name
}

# SSH Connection outputs
output "ssh_private_key_path" {
  description = "Path to the generated SSH private key"
  value       = module.backend.ssh_private_key_path
}

output "ssh_connection_command" {
  description = "SSH command to connect to the EC2 instance"
  value       = module.backend.ssh_connection_command
}

output "ssh_tunnel_command" {
  description = "SSH tunnel command for database access"
  value       = module.backend.ssh_tunnel_command
  sensitive   = true
}

# CI/CD outputs for newsapp-backend
output "news_backend_ecr_repository_url" {
  description = "URL of the ECR repository for newsapp-backend"
  value       = module.news_backend_cicd.ecr_repository_url
}

output "news_backend_codepipeline_name" {
  description = "Name of the CodePipeline for newsapp-backend"
  value       = module.news_backend_cicd.codepipeline_name
}

# CI/CD outputs for newsapp-collector
output "news_collector_ecr_repository_url" {
  description = "URL of the ECR repository for newsapp-collector"
  value       = module.news_collector_cicd.ecr_repository_url
}

output "news_collector_codepipeline_name" {
  description = "Name of the CodePipeline for newsapp-collector"
  value       = module.news_collector_cicd.codepipeline_name
}

# CI/CD outputs for newsapp-agentic-ai
output "news_agentic_ecr_repository_url" {
  description = "URL of the ECR repository for newsapp-agentic-ai"
  value       = module.news_agentic_cicd.ecr_repository_url
}

output "news_agentic_codepipeline_name" {
  description = "Name of the CodePipeline for newsapp-agentic-ai"
  value       = module.news_agentic_cicd.codepipeline_name
}

# Frontend outputs
output "frontend_website_url" {
  description = "URL of the React application"
  value       = module.news_frontend.website_url
}

output "frontend_cloudfront_domain" {
  description = "CloudFront domain name for the React app"
  value       = module.news_frontend.cloudfront_domain_name
}

output "frontend_codepipeline_name" {
  description = "CodePipeline name for the React app"
  value       = module.news_frontend_cicd.codepipeline_name
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

output "api_domain" {
  description = "API domain for backend REST API (HTTPS)"
  value       = var.enable_route53 && var.domain_name != "" ? "api.${var.domain_name}" : ""
}

output "api1_domain" {
  description = "API1 domain for backend WebSocket (HTTPS)"
  value       = var.enable_route53 && var.domain_name != "" ? "api1.${var.domain_name}" : ""
}

# Combined domain URLs for easy access
output "application_urls" {
  description = "All application URLs"
  value = {
    frontend_cloudfront = module.news_frontend.website_url
    frontend_custom     = var.enable_route53 && var.domain_name != "" ? "https://${var.domain_name}" : "Not configured"
    api_https           = var.enable_route53 && var.domain_name != "" ? "https://api.${var.domain_name}" : "Not configured"
    api1_websocket      = var.enable_route53 && var.domain_name != "" ? "wss://api1.${var.domain_name}" : "Not configured"
    backend_elastic_ip  = "http://${module.backend.elastic_ip}:5000"
    backend_note        = "Use api_https for production (HTTPS). backend_elastic_ip for testing only (HTTP)"
  }
}
