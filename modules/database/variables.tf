variable "namespace" {
  description = "Project namespace"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where RDS will be created"
  type        = string
}

variable "backend_security_group_id" {
  description = "Security group ID of the backend EC2 instances"
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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs used to create the RDS DB subnet group (must span at least two AZs)"
  type        = list(string)
}