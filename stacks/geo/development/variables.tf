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