# backend/variables.tf
variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

locals {
  tags = {
    Project     = var.project
    Environment = var.project
    Managed_by  = "terraform"
    Owner       = "tthau"
  }
}
