variable "namespace" {
  description = "Namespace for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "create_route53_records" {
  description = "Whether to create Route53 DNS records (must be determinable at plan time)"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Custom domain name for CloudFront (e.g., sabeeltech-esg.dev)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for CloudFront (must be in us-east-1)"
  type        = string
  default     = ""
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID for creating DNS records"
  type        = string
  default     = ""
}