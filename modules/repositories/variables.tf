# modules/repositories/variables.tf
variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "repositories" {
  type = map(object({
    name        = string
    description = string
    branch      = string
  }))
}

locals {
  tags = {
    Project     = var.project
    Environment = var.environment
    Managed_by  = "terraform"
  }
}
