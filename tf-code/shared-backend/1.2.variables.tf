# shared-backend/1.2.variables.tf



variable "region" {
  description = "AWS region"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
}


locals {
  name_prefix = "${var.owner}-${var.project}-${var.environment}"

  tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    Manged_by   = "terraform"
  }
}
