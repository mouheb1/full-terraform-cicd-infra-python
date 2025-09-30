variable "domain_name" {
  description = "The domain name for the hosted zone (e.g., mydomain.com)"
  type        = string
}

variable "ec2_public_ip" {
  description = "Public IP address of the EC2 instance for API subdomain"
  type        = string
}

variable "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  type        = string
}

variable "cloudfront_hosted_zone_id" {
  description = "CloudFront distribution hosted zone ID"
  type        = string
}

variable "namespace" {
  description = "The namespace for resource naming"
  type        = string
}

variable "environment" {
  description = "The environment name"
  type        = string
}

variable "create_www_redirect" {
  description = "Whether to create www.domain.com redirect"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}