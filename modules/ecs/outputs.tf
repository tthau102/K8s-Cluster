# modules/ecs/outputs.tf
output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "service_names" {
  value = {
    for k, v in aws_ecs_service.services : k => v.name
  }
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}
