variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "geo_dev"
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

# Flask Auth Backend configuration
variable "jwt_secret_key" {
  description = "JWT secret key for Flask authentication backend"
  type        = string
  default     = ""
  sensitive   = true
}

# Domain configuration
variable "domain_name" {
  description = "Domain name for DNS setup (e.g., mydomain.com). Leave empty to skip DNS configuration"
  type        = string
  default     = ""
}

variable "enable_route53" {
  description = "Enable Route 53 DNS configuration"
  type        = bool
  default     = false
}