variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "namespace" {
  description = "The namespace/project name"
  type        = string
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

# Note: github_token is no longer needed with CodeStar Connection (GitHub v2)
# Keeping this commented for backwards compatibility
# variable "github_token" {
#   description = "GitHub personal access token for webhook access"
#   type        = string
#   sensitive   = true
# }

variable "backend_instance_id" {
  description = "EC2 instance ID for CodeDeploy target"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}