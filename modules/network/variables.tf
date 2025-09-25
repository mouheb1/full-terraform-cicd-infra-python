variable "environment" {
  description = "The STA environment name."
  type        = string
}

variable "namespace" {
  description = "The namespace under which to launch a specific RT environment. The comination of namespace + environment must be globally unique."
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

variable "tags" {
  description = "Project tags to be attached to resources"
  type        = object({})
  default     = {}
}
