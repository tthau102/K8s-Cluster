# modules/mongodb/variables.tf
variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "container_ports" {
  type        = list(number)
  description = "List of container ports that need to be allowed"
}

locals {
  tags = {
    Project     = var.project
    Environment = var.environment
    Managed_by  = "terraform"
  }
}
