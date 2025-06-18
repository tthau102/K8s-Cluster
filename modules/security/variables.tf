# modules/security/variables.tf
variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "additional_tags" {
  description = "Additional tags for security groups"
  type        = map(string)
  default     = {}
}