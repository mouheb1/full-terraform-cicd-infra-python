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