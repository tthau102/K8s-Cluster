# environments/dev/outputs.tf
output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = module.network.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = module.network.public_subnet_ids
}

output "mongodb_private_ip" {
  description = "MongoDB Private IP"
  value       = module.mongodb.mongodb_private_ip
}

output "ecr_repository_urls" {
  description = "ECR Repository URLs"
  value       = module.ecr.repository_urls
}

output "codecommit_repository_urls" {
  description = "CodeCommit Repository URLs"
  value       = module.repositories.repository_urls
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS Name"
  value       = module.ecs.alb_dns_name
}

output "ecs_cluster_name" {
  description = "ECS Cluster Name"
  value       = module.ecs.cluster_name
}

output "ecs_service_names" {
  description = "ECS Service Names"
  value       = module.ecs.service_names
}

output "pipeline_arns" {
  description = "CodePipeline ARNs"
  value       = module.pipeline.pipeline_arns
}

output "resource_group_arns" {
  description = "Resource Group ARNs"
  value       = module.resource_groups.group_arns
}
