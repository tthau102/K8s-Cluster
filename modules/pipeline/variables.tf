# modules/pipeline/variables.tf
variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "repository_configs" {
  type = map(object({
    repository_name = string
    branch_name     = string
    service_name    = string
    container_name  = string
    ecr_repo_url    = string
    build_specfile  = string
  }))
  description = "Configuration for each repository/service pipeline"
}

variable "ecs_cluster_name" {
  type        = string
  description = "Name of the ECS cluster"
}

variable "pipeline_notification_arn" {
  type        = string
  description = "ARN of the SNS topic for pipeline notifications"
  default     = ""
}

locals {
  tags = {
    Project     = var.project
    Environment = var.environment
    Managed_by  = "terraform"
  }
}
