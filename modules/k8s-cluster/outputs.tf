# modules/k8s-cluster/outputs.tf
output "master_ips" {
  description = "Private IP addresses of master nodes"
  value       = [for inst in var.master_instances : inst.private_ip]
}

output "worker_ips" {
  description = "Private IP addresses of worker nodes"
  value       = [for inst in var.worker_instances : inst.private_ip]
}

output "kubeconfig_path" {
  description = "Path to kubeconfig file"
  value       = "${path.module}/kubeconfig"
}

output "inventory_path" {
  description = "Path to Ansible inventory file"
  value       = local_file.ansible_inventory.filename
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = "https://${var.bastion_ip}:6443"
}
