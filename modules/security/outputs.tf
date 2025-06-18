# modules/security/outputs.tf
output "k8s_master_sg_id" {
  description = "Security group ID for K8s master nodes"
  value       = aws_security_group.k8s_master.id
}

output "k8s_worker_sg_id" {
  description = "Security group ID for K8s worker nodes"
  value       = aws_security_group.k8s_worker.id
}

output "alb_sg_id" {
  description = "Security group ID for ALB"
  value       = aws_security_group.alb.id
}

output "all_sg_ids" {
  description = "Map of all security group IDs"
  value = {
    master = aws_security_group.k8s_master.id
    worker = aws_security_group.k8s_worker.id
    alb    = aws_security_group.alb.id
  }
}