variable "environment" {
  description = "The STA environment name."
  type        = string
}

variable "python_env" {
  description = "Python environment (development, production, etc.)"
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

variable "backend_name" {
  description = "Name identifier for the primary backend (used in pipeline naming)"
  type        = string
}

variable "second_github_repo" {
  description = "Second backend GitHub repository name"
  type        = string
  default     = ""
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

# Django configuration variables
variable "django_secret_key" {
  description = "Django secret key for cryptographic operations"
  type        = string
  default     = ""
  sensitive   = true
}