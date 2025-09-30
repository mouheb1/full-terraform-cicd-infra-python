variable "domain_name" {
  description = "Domain name for the certificate (e.g., sabeeltech-esg.dev)"
  type        = string
}

variable "namespace" {
  description = "Namespace for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "backend_elastic_ip" {
  description = "Backend EC2 Elastic IP for API subdomain"
  type        = string
  default     = ""
}
