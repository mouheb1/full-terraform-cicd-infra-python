output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.network.private_subnet_ids
}

output "backend_instance_id" {
  description = "ID of the backend EC2 instance"
  value       = module.backend.instance_id
}

output "backend_public_ip" {
  description = "Public IP address of the backend EC2 instance"
  value       = module.backend.instance_public_ip
}

output "backend_public_dns" {
  description = "Public DNS name of the backend EC2 instance"
  value       = module.backend.instance_public_dns
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.cicd.ecr_repository_url
}

output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = module.cicd.codepipeline_name
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = module.cicd.codebuild_project_name
}

output "codestar_connection_arn" {
  description = "ARN of the CodeStar Connection for GitHub"
  value       = module.cicd.codestar_connection_arn
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

# Add CloudFront outputs
output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.s3.bucket_arn
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name for serving images"
  value       = module.s3.cloudfront_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.s3.cloudfront_distribution_id
}

output "s3_vpc_endpoint_id" {
  description = "S3 VPC endpoint ID"
  value       = module.s3.vpc_endpoint_id
}