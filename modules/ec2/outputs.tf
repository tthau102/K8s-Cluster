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

output "master_instance_details" {
  description = "Detailed information about master instances"
  value = {
    for i, instance in aws_instance.master : i => {
      id         = instance.id
      private_ip = instance.private_ip
      subnet_id  = instance.subnet_id
      az         = instance.availability_zone
      hostname   = "k8s-master-${i + 1}"
    }
  }
}

output "worker_instance_details" {
  description = "Detailed information about worker instances"
  value = {
    for i, instance in aws_instance.worker : i => {
      id         = instance.id
      private_ip = instance.private_ip
      subnet_id  = instance.subnet_id
      az         = instance.availability_zone
      hostname   = "k8s-worker-${i + 1}"
    }
  }
}

output "key_pair_name" {
  description = "Name of the created key pair"
  value       = aws_key_pair.k8s_key.key_name
}

output "master_iam_role_arn" {
  description = "ARN of the master IAM role"
  value       = aws_iam_role.k8s_master.arn
}

output "worker_iam_role_arn" {
  description = "ARN of the worker IAM role"
  value       = aws_iam_role.k8s_worker.arn
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