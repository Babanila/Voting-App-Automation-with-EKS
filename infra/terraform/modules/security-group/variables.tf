# General Configuration
variable "name" {
  description = "Name of the security group"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_-]{0,127}$", var.name))
    error_message = "Security group name must start with a letter, contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "description" {
  description = "Description of the security group"
  type        = string
  default     = "Security group managed by Terraform"
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

variable "name_prefix" {
  description = "Use name prefix instead of exact name (useful for reusable modules)"
  type        = string
  default     = ""
}


# Ingress Rules
variable "ingress_rules" {
  description = "List of ingress rules"
  type = list(object({
    description              = optional(string, "")
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_blocks              = optional(list(string), [])
    ipv6_cidr_blocks         = optional(list(string), [])
    source_security_group_id = optional(string, "")  # Changed from security_groups
    self                     = optional(bool, false)
    prefix_list_ids          = optional(list(string), [])
  }))
  default = []
}

# Egress Rules
variable "egress_rules" {
  description = "List of egress rules"
  type = list(object({
    description              = optional(string, "")
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_blocks              = optional(list(string), [])
    ipv6_cidr_blocks         = optional(list(string), [])
    source_security_group_id = optional(string, "")
    self                     = optional(bool, false)
    prefix_list_ids          = optional(list(string), [])
  }))
  default = []
}


# Default Egress (allow all)
variable "enable_default_egress" {
  description = "Enable default egress rule (allow all outbound)"
  type        = bool
  default     = true
}

variable "default_egress_cidr_blocks" {
  description = "CIDR blocks for default egress rule"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}


# Tags
variable "tags" {
  description = "Map of tags to apply to the security group"
  type        = map(string)
  default     = {}
}
