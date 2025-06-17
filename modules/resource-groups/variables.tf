# modules/resource-groups/variables.tf
variable "project" {
  type = string
}

variable "environment" {
  type = string
}

locals {
  tags = {
    Project     = var.project
    Environment = var.environment
    Managed_by  = "terraform"
  }
}
