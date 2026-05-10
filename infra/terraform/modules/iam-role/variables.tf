variable "name" {
  description = "Name of the IAM role"
  type        = string
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

variable "max_session_duration" {
  description = "Maximum session duration in seconds"
  type        = number
  default     = 3600
}

variable "trusted_services" {
  description = "List of AWS services that can assume this role"
  type        = list(string)
  default     = []
}

variable "trusted_arns" {
  description = "List of ARNs that can assume this role"
  type        = list(string)
  default     = []
}

variable "trusted_accounts" {
  description = "List of AWS account IDs that can assume this role"
  type        = list(string)
  default     = []
}

variable "assume_role_policy" {
  description = "Custom assume role policy (overrides all trusted_entities if provided)"
  type        = string
  default     = ""
}

variable "managed_policy_arns" {
  description = "List of managed policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policies to attach to the role"
  type = map(object({
    name   = optional(string, "")
    policy = string
  }))
  default = {}
}

variable "policies" {
  description = "Map of IAM policies to create and attach"
  type = map(object({
    description = optional(string, "IAM policy managed by Terraform")
    path        = optional(string, "/")
    policy      = string
    attach      = optional(bool, true)
  }))
  default = {}
}

variable "create_instance_profile" {
  description = "Whether to create an instance profile for the role"
  type        = bool
  default     = false
}

variable "permissions_boundary_arn" {
  description = "ARN of the permissions boundary policy"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
