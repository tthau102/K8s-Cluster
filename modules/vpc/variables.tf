# modules/vpc/variables.tf
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateways for private subnets"
  type        = bool
  default     = false
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC endpoints for S3 and ECR"
  type        = bool
  default     = false
}

variable "availability_zones_count" {
  description = "Number of AZs to deploy across"
  type        = number
  default     = 3
}

variable "additional_tags" {
  description = "Additional tags to merge with default provider tags"
  type        = map(string)
  default     = {}
}