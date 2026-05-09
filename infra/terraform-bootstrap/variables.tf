variable "project_bucket_name" {
  type = string
}

variable "key_pair_name" {
  description = "The name of the AWS key pair to use for SSH access"
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "name" {
  type        = string
  description = "Used for naming resources"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", lower(var.name)))
    error_message = "name must contain only lowercase letters, numbers, and hyphens."
  }
}
