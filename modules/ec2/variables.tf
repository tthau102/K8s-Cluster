# modules/ec2/variables.tf

variable "master_count" {
  description = "Number of master nodes"
  type        = number
  default     = 3
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "master_instance_type" {
  description = "Instance type for master nodes"
  type        = string
  default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "Instance type for worker nodes"
  type        = string
  default     = "t3.large"
}

variable "kubernetes_version" {
  description = "Kubernetes version to install"
  type        = string
  default     = "1.28"
}

variable "containerd_version" {
  description = "Containerd version to install"
  type        = string
  default     = "1.6.24-1"
}

variable "public_key" {
  description = "Public key for SSH access"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "master_security_group_id" {
  description = "Security group ID for master nodes"
  type        = string
}

variable "worker_security_group_id" {
  description = "Security group ID for worker nodes"
  type        = string
}

variable "additional_tags" {
  description = "Additional tags to merge with default provider tags"
  type        = map(string)
  default     = {}
}