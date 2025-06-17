# modules/ecr/variables.tf
variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "repositories" {
  type    = list(string)
  default = ["frontend", "backend"]
}

locals {
  tags = {
    Project     = var.project
    Environment = var.environment
    Managed_by  = "terraform"
  }
}
