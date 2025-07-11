# modules/alb/variables.tf

variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "master_instance_ids" {
  description = "List of master instance IDs"
  type        = list(string)
  default     = []
}

variable "worker_instance_ids" {
  description = "List of worker instance IDs"
  type        = list(string)
}

variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for HTTPS listener"
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "SSL policy for HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "enable_access_logs" {
  description = "Enable access logs for ALB"
  type        = bool
  default     = true
}

variable "access_logs_retention_days" {
  description = "Number of days to retain access logs"
  type        = number
  default     = 30
}

variable "expose_api_server" {
  description = "Expose Kubernetes API server through ALB"
  type        = bool
  default     = false
}

variable "additional_tags" {
  description = "Additional tags for ALB resources"
  type        = map(string)
  default     = {}
}
