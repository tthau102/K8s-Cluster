# modules/ec2/variables.tf
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "master_sg_id" {
  description = "Master security group ID"
  type        = string
}

variable "worker_sg_id" {
  description = "Worker security group ID"
  type        = string
}

variable "master_instance_type" {
  description = "Master instance type"
  type        = string
  default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "Worker instance type"
  type        = string
  default     = "t3.medium"
}

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

variable "key_pair_name" {
  description = "EC2 Key Pair name"
  type        = string
}

variable "additional_tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}