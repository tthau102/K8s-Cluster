# modules/ec2/outputs.tf

output "master_instance_ids" {
  description = "IDs of the master instances"
  value       = aws_instance.master[*].id
}

output "worker_instance_ids" {
  description = "IDs of the worker instances"
  value       = aws_instance.worker[*].id
}

output "master_private_ips" {
  description = "Private IP addresses of master nodes"
  value       = aws_instance.master[*].private_ip
}

output "worker_private_ips" {
  description = "Private IP addresses of worker nodes"
  value       = aws_instance.worker[*].private_ip
}

output "cluster_info" {
  description = "Summary information about the K8s cluster"
  value = {
    cluster_name     = local.name_prefix
    master_count     = var.master_count
    worker_count     = var.worker_count
    total_nodes      = var.master_count + var.worker_count
    k8s_version      = var.kubernetes_version
    first_master_ip  = aws_instance.master[0].private_ip
  }
}