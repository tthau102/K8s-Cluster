# backend/variables.tf
variable "project" {
  type = string
}

variable "region" {
  type = string
}

locals {
  tags = {
    Project     = var.project
    Environment = "management"
    Managed_by  = "terraform"
  }
}
