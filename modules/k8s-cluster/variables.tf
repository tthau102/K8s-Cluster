# modules/k8s-cluster/variables.tf
variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "tth-k8s-cluster"
}

variable "master_instances" {
  description = "List of master instance objects with private_ip"
  type = list(object({
    private_ip = string
    id         = string
  }))
}

variable "worker_instances" {
  description = "List of worker instance objects with private_ip"
  type = list(object({
    private_ip = string
    id         = string
  }))
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "bastion_ip" {
  description = "Bastion host public IP"
  type        = string
}

variable "kube_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31.0"
}

