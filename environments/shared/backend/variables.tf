# backend/variables.tf
variable "project" {
  description = "Project name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "backend"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "devops-team"
}

locals {
  name_prefix = "${var.owner}-${var.project}-${var.environment}"

  tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    Managed_by  = "terraform"
  }
}
