variable "environment" {
  type        = string
  description = "The environment for which to deploy resources (e.g., dev, staging, prod)"
}

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "cluster_instance_type" {
  type    = list(string)
  default = ["t3.large"]
}

variable "cluster_min_size" {
  type    = number
  default = 1
}

variable "cluster_max_size" {
  type    = number
  default = 2
}

variable "cluster_desired_size" {
  type    = number
  default = 1
}

variable "ec2_instances" {
  description = "A map of instance identifiers to Name tags"
  type        = map(string)
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "key_pair_name" {
  description = "The name of the AWS key pair to use for SSH access"
  type        = string
}

variable "availability_zones" {
  type = list(string)
}

variable "cidr_block" {
  type = string
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "database_subnet_cidrs" {
  type = list(string)
}

variable "elasticache_subnet_cidrs" {
  type = list(string)
}

variable "flow_logs_destination_type" {
  type = string
}

variable "author_name" {
  type        = string
  description = "Used for naming resources"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", lower(var.author_name)))
    error_message = "author_name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "my_ip_cidr" {
  type        = string
  description = "Your IP for SSH access"
}
