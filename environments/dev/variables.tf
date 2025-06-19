# environments/dev/variables.tf
variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-5" 
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones_count" {
  description = "Number of AZs to deploy across"
  type        = number
  default     = 3
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateways for private subnets"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC endpoints for S3 and ECR"
  type        = bool
  default     = true
}

# EC2 Variables - THIẾU TRƯỚC ĐÂY
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

# Core Variables
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "owner" {
  description = "Owner"
  type        = string
}

locals {
  tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    Managed_by  = "terraform"
  }
}