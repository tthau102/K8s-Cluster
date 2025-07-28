# dev/1.4.variables.tf


variable "region" {
  description = "AWS region"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "Project name must contain only lowercase letters, numbers and hyphens"
  }
}

variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "owner" {
  description = "Owner of the resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.owner))
    error_message = "Owner must contain only lowercase letters, numbers and hyphens"
  }
}
