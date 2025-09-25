variable "environment" {
  description = "The STA environment name."
  type        = string
}

variable "node_env" {
  description = "Node.js environment (development, production, etc.)"
  type        = string
  default     = "production"
}

variable "namespace" {
  description = "The namespace under which to launch a specific RT environment. The combination of namespace + environment must be globally unique."
  type        = string
}

variable "branch_name" {
  description = "The branch name to use for the CodePipeline source stage."
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the backend server"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "AWS Key Pair name for EC2 access"
  type        = string
  default     = null
}

variable "github_owner" {
  description = "GitHub repository owner/organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch to monitor for changes"
  type        = string
  default     = "develop"
}


variable "tags" {
  description = "Project tags to be attached to resources"
  type        = object({})
  default     = {}
}

variable "profile" {
  description = "The AWS CLI profile to use."
  type        = string  
}

variable "region" {
  description = "The AWS region to deploy resources in."
  type        = string  
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
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