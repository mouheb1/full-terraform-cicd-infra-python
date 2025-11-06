variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "news_admin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

# Domain configuration
variable "domain_name" {
  description = "Domain name for DNS setup (e.g., newsaidemo.dev). Leave empty to skip DNS configuration"
  type        = string
  default     = ""
}

variable "enable_route53" {
  description = "Enable Route 53 DNS configuration"
  type        = bool
  default     = false
}
