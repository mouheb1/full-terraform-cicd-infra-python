variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "node_env" {
  description = "Node.js environment (development, production, etc.)"
  type        = string
  default     = "production"
}

variable "namespace" {
  description = "The namespace/project name"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where the EC2 instance will be launched"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the EC2 instance"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "AWS Key Pair name for EC2 access"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

# Database connection variables
variable "db_host" {
  description = "Database host endpoint"
  type        = string
  default     = ""
}

variable "db_port" {
  description = "Database port"
  type        = string
  default     = "5432"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = ""
}

variable "db_user" {
  description = "Database username"
  type        = string
  default     = ""
}

variable "db_password" {
  description = "Database password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "s3_access_policy_arn" {
  description = "S3 access policy ARN to attach to EC2 role"
  type        = string
  default     = null
}

# JWT configuration variables
variable "jwt_private_key" {
  description = "JWT private key for token signing"
  type        = string
  default     = ""
  sensitive   = true
}

variable "jwt_public_key" {
  description = "JWT public key for token verification"
  type        = string
  default     = ""
  sensitive   = true
}

variable "jwt_refresh_token_private_key" {
  description = "JWT refresh token private key"
  type        = string
  default     = ""
  sensitive   = true
}