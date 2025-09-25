# Infrastructure outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.shared_infrastructure.vpc_id
}

output "backend_public_ip" {
  description = "Public IP address of the backend EC2 instance"
  value       = module.shared_infrastructure.backend_public_ip
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