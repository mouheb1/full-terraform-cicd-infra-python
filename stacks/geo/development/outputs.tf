# Infrastructure outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.geo_environment.vpc_id
}

output "backend_public_ip" {
  description = "Public IP address of the backend EC2 instance"
  value       = module.geo_environment.backend_public_ip
}

output "backend_public_dns" {
  description = "Public DNS name of the backend EC2 instance"
  value       = module.geo_environment.backend_public_dns
}

# Database outputs
output "database_endpoint" {
  description = "Database endpoint"
  value       = module.geo_environment.database_endpoint
}

output "database_port" {
  description = "Database port"
  value       = module.geo_environment.database_port
}

output "database_name" {
  description = "Database name"
  value       = module.geo_environment.database_name
}

# SSH Connection outputs
output "ssh_private_key_path" {
  description = "Path to the generated SSH private key"
  value       = module.geo_environment.ssh_private_key_path
}

output "ssh_connection_command" {
  description = "SSH command to connect to the EC2 instance"
  value       = module.geo_environment.ssh_connection_command
}

output "ssh_tunnel_command" {
  description = "SSH tunnel command for database access"
  value       = module.geo_environment.ssh_tunnel_command
  sensitive   = true
}

# CI/CD outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.geo_environment.ecr_repository_url
}

output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = module.geo_environment.codepipeline_name
}