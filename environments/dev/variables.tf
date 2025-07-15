# environments/dev/variables.tf

# =============================================================================
# VARIABLE DEFINITIONS
# Định nghĩa tất cả variables sử dụng trong infrastructure
# =============================================================================

# ===========================================
# PROJECT & ENVIRONMENT VARIABLES
# ===========================================

variable "project" {
  description = "Project name - sử dụng trong naming convention"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment identifier (dev/staging/prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Owner/Team identifier cho resource tracking"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.owner))
    error_message = "Owner must contain only lowercase letters, numbers, and hyphens."
  }
}

# ===========================================
# AWS REGION & NETWORKING VARIABLES
# ===========================================

variable "region" {
  description = "AWS region để deploy infrastructure"
  type        = string
  default     = "ap-southeast-5"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.region))
    error_message = "Region must be a valid AWS region format."
  }
}

variable "vpc_cidr" {
  description = "CIDR block cho VPC - private IP range"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones_count" {
  description = "Số lượng Availability Zones sử dụng cho high availability"
  type        = number
  default     = 3

  validation {
    condition     = var.availability_zones_count >= 2 && var.availability_zones_count <= 6
    error_message = "Availability zones count must be between 2 and 6."
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway cho private subnet internet access"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC endpoints cho AWS services (S3, ECR)"
  type        = bool
  default     = true
}

# ===========================================
# KUBERNETES CLUSTER VARIABLES
# ===========================================

variable "master_count" {
  description = "Số lượng master nodes - nên là số lẻ cho etcd quorum"
  type        = number
  default     = 3

  validation {
    condition     = var.master_count >= 1 && var.master_count <= 7 && var.master_count % 2 == 1
    error_message = "Master count must be an odd number between 1 and 7."
  }
}

variable "worker_count" {
  description = "Số lượng worker nodes"
  type        = number
  default     = 3

  validation {
    condition     = var.worker_count >= 1 && var.worker_count <= 50
    error_message = "Worker count must be between 1 and 50."
  }
}

variable "master_instance_type" {
  description = "Instance type cho master nodes"
  type        = string
  default     = "t3.medium"

  validation {
    condition = contains([
      "t3.medium", "t3.large", "t3.xlarge",
      "m5.large", "m5.xlarge", "m5.2xlarge",
      "c5.large", "c5.xlarge", "c5.2xlarge"
    ], var.master_instance_type)
    error_message = "Master instance type must be suitable for K8s control plane workloads."
  }
}

variable "worker_instance_type" {
  description = "Instance type cho worker nodes"
  type        = string
  default     = "t3.large"

  validation {
    condition = contains([
      "t3.medium", "t3.large", "t3.xlarge", "t3.2xlarge",
      "m5.large", "m5.xlarge", "m5.2xlarge", "m5.4xlarge",
      "c5.large", "c5.xlarge", "c5.2xlarge", "c5.4xlarge"
    ], var.worker_instance_type)
    error_message = "Worker instance type must be suitable for application workloads."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version to install (major.minor format)"
  type        = string
  default     = "1.28"

  validation {
    condition     = can(regex("^1\\.(2[4-9]|[3-9][0-9])$", var.kubernetes_version))
    error_message = "Kubernetes version must be 1.24 or newer in format 'major.minor'."
  }
}

variable "containerd_version" {
  description = "Containerd version compatible với K8s version"
  type        = string
  default     = "1.6.24-1"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+-[0-9]+$", var.containerd_version))
    error_message = "Containerd version must be in format 'x.y.z-n'."
  }
}

# ===========================================
# LOAD BALANCER CONFIGURATION
# ===========================================

variable "ssl_certificate_arn" {
  description = "SSL Certificate ARN cho HTTPS listener"
  type        = string
  default     = null
}

variable "enable_deletion_protection" {
  description = "Enable ALB deletion protection"
  type        = bool
  default     = false
}

variable "access_logs_retention_days" {
  description = "ALB access logs retention in days"
  type        = number
  default     = 30

  validation {
    condition     = var.access_logs_retention_days >= 1 && var.access_logs_retention_days <= 3653
    error_message = "Access logs retention must be between 1 and 3653 days."
  }
}

# Note: Local values được định nghĩa trong locals.tf
