# modules/alb/outputs.tf

output "alb_arn" {
  description = "ARN of the ALB"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB"
  value       = aws_lb.main.zone_id
}

output "k8s_ingress_target_group_arn" {
  description = "ARN of K8s ingress target group"
  value       = aws_lb_target_group.k8s_ingress.arn
}

output "k8s_api_target_group_arn" {
  description = "ARN of K8s API target group"
  value       = var.expose_api_server ? aws_lb_target_group.k8s_api[0].arn : null
}

output "access_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  value       = aws_s3_bucket.alb_logs.bucket
}

output "load_balancer_info" {
  description = "ALB summary information"
  value = {
    name               = aws_lb.main.name
    dns_name           = aws_lb.main.dns_name
    hosted_zone_id     = aws_lb.main.zone_id
    load_balancer_type = aws_lb.main.load_balancer_type
    scheme             = aws_lb.main.scheme
  }
}
