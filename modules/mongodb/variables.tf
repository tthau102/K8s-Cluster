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

variable "subnet_id" {
  type = string
}

variable "ecs_tasks_sg_id" {
  type = string
}

variable "mongodb_sg_id" {
  type = string
}

locals {
  tags = {
    Project     = var.project
    Environment = var.environment
    Managed_by  = "terraform"
  }
}
