variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "services" {
  type = map(object({
    container_name    = string
    container_image   = string
    container_port    = number
    desired_count     = number
    health_check_path = string
    health_check_port = number
    environment = list(object({
      name  = string
      value = string
    }))
    secrets = list(object({
      name      = string
      valueFrom = string
    }))
  }))
  description = "Configuration for ECS services and their containers"
}

variable "alb_sg_id" {
  type = string
}

variable "ecs_tasks_sg_id" {
  type = string
}

locals {
  tags = {
    Project     = var.project
    Environment = var.environment
    Managed_by  = "terraform"
  }
}
