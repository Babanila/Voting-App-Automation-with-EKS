# General Configuration
variable "name" {
  description = "Name of the IAM role"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_-]{0,63}$", var.name))
    error_message = "Role name must start with a letter, contain only alphanumeric characters, hyphens, and underscores, and be max 64 characters."
  }
}

variable "description" {
  description = "Description of the IAM role"
  type        = string
  default     = "IAM role managed by Terraform"
}

variable "path" {
  description = "Path for the IAM role"
  type        = string
  default     = "/"
}


# Trust Relationship Configuration
variable "trusted_entities" {
  description = "List of trusted entities (AWS services, accounts, or ARNs)"
  type = list(object({
    type        = string # "service", "account", "arn", "federated"
    identifiers = list(string)
    condition = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
  }))
  default = []
}

variable "assume_role_policy" {
  description = "Custom assume role policy (overrides trusted_entities if provided)"
  type        = string
  default     = ""
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds"
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "Max session duration must be between 3600 (1 hour) and 43200 (12 hours)."
  }
}


# Managed Policies
variable "managed_policy_arns" {
  description = "List of managed policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}


# Inline Policies
variable "inline_policies" {
  description = "Map of inline policies to attach to the role"
  type = map(object({
    name   = optional(string, "")
    policy = string
  }))
  default = {}
}


# Instance Profile (for EC2)
variable "create_instance_profile" {
  description = "Whether to create an instance profile for the role"
  type        = bool
  default     = false
}


# IAM Policies to Create
variable "policies" {
  description = "Map of IAM policies to create and optionally attach to the role"
  type = map(object({
    description = optional(string, "IAM policy managed by Terraform")
    path        = optional(string, "/")
    policy      = string
    attach      = optional(bool, true)
  }))
  default = {}
}


# Permissions Boundary
variable "permissions_boundary_arn" {
  description = "ARN of the permissions boundary policy"
  type        = string
  default     = ""
}


# Tags
variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
