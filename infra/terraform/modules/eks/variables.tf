# Cluster Configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,99}$", var.cluster_name))
    error_message = "Cluster name must start with a letter, contain only alphanumeric characters and hyphens, and be max 100 characters."
  }
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"

  validation {
    condition     = can(regex("^1\\.(2[7-9]|3[0-9])$", var.cluster_version))
    error_message = "Cluster version must be 1.27 or higher."
  }
}

variable "cluster_description" {
  description = "Description of the EKS cluster"
  type        = string
  default     = "EKS cluster managed by Terraform"
}


# Network Configuration
variable "vpc_id" {
  description = "ID of the VPC where the cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnets are required for EKS cluster."
  }
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to the EKS API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Enable private access to the EKS API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks allowed to access the public endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}


# Node Group Configuration
variable "node_groups" {
  description = "Map of EKS managed node group configurations"
  type = map(object({
    instance_types = list(string)
    capacity_type  = optional(string, "ON_DEMAND")
    disk_size      = optional(number, 50)
    min_size       = number
    max_size       = number
    desired_size   = number
    ami_type       = optional(string, "AL2023_x86_64_STANDARD")
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }
}


# IAM Configuration
variable "cluster_role_arn" {
  description = "ARN of the IAM role for the EKS cluster (optional, will create if not provided)"
  type        = string
  default     = ""
}

variable "node_role_arn" {
  description = "ARN of the IAM role for the EKS node groups (optional, will create if not provided)"
  type        = string
  default     = ""
}

variable "cluster_policy_arns" {
  description = "List of IAM policy ARNs to attach to the cluster role"
  type        = list(string)
  default     = []
}

variable "node_policy_arns" {
  description = "List of IAM policy ARNs to attach to the node role"
  type        = list(string)
  default     = []
}


# Add-ons Configuration
variable "enable_cluster_addons" {
  description = "Map of EKS add-ons to enable"
  type = map(object({
    version                  = optional(string, null)
    resolve_conflicts_on_create = optional(string, "OVERWRITE")
    resolve_conflicts_on_update = optional(string, "OVERWRITE")
  }))
  default = {
    coredns = {
      version = null
    }
    kube-proxy = {
      version = null
    }
    vpc-cni = {
      version = null
    }
    aws-ebs-csi-driver = {
      version = null
    }
  }
}


# Access Configuration
variable "aws_auth_roles" {
  description = "List of IAM roles to add to aws-auth ConfigMap"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "aws_auth_users" {
  description = "List of IAM users to add to aws-auth ConfigMap"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}


# Logging Configuration
variable "cluster_log_types" {
  description = "List of control plane log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_log_retention_days" {
  description = "Number of days to retain cluster logs in CloudWatch"
  type        = number
  default     = 30

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.cluster_log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention value."
  }
}


# Encryption Configuration
variable "enable_envelope_encryption" {
  description = "Enable envelope encryption for secrets"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for envelope encryption (optional, will create if not provided)"
  type        = string
  default     = ""
}


# Tags
variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_tags" {
  description = "Map of additional tags specific to the cluster"
  type        = map(string)
  default     = {}
}
