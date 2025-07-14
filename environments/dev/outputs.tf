# environments/dev/outputs.tf

# =============================================================================
# INFRASTRUCTURE OUTPUTS
# Thông tin về resources được tạo để sử dụng và reference
# =============================================================================

# ===========================================
# NETWORKING OUTPUTS
# ===========================================

# VPC thông tin cơ bản
output "vpc_info" {
  description = "VPC configuration details"
  value = {
    id                 = module.vpc.vpc_id
    cidr_block         = module.vpc.vpc_cidr_block
    name               = "${local.name_prefix}-vpc"
    region             = var.region
    availability_zones = local.azs
  }
}

# Subnet information theo type
output "subnets" {
  description = "Subnet information organized by type"
  value = {
    public = {
      ids   = module.vpc.public_subnets
      cidrs = module.vpc.public_subnets_cidr_blocks
      count = length(module.vpc.public_subnets)
    }
    private = {
      ids   = module.vpc.private_subnets
      cidrs = module.vpc.private_subnets_cidr_blocks
      count = length(module.vpc.private_subnets)
    }
  }
}

# Network gateway information
output "network_gateways" {
  description = "Network gateway and routing information"
  value = {
    internet_gateway_id = module.vpc.igw_id
    nat_gateway_ids     = module.vpc.natgw_ids
    nat_public_ips      = module.vpc.nat_public_ips
  }
}

# ===========================================
# SECURITY OUTPUTS
# ===========================================

# Security Groups information
output "security_groups" {
  description = "Security group IDs cho các components"
  value = {
    k8s_master = module.k8s_master_sg.security_group_id
    k8s_worker = module.k8s_worker_sg.security_group_id
    alb        = module.alb_sg.security_group_id
  }
}

# ===========================================
# COMPUTE OUTPUTS
# ===========================================

# K8s Master Nodes information
output "k8s_masters" {
  description = "Kubernetes master nodes details"
  value = {
    instance_ids  = [for instance in module.k8s_masters : instance.id]
    private_ips   = [for instance in module.k8s_masters : instance.private_ip]
    instance_type = var.master_instance_type
    count         = var.master_count
  }
}

# K8s Worker Nodes information
output "k8s_workers" {
  description = "Kubernetes worker nodes details"
  value = {
    instance_ids  = [for instance in module.k8s_workers : instance.id]
    private_ips   = [for instance in module.k8s_workers : instance.private_ip]
    instance_type = var.worker_instance_type
    count         = var.worker_count
  }
}

# All K8s nodes với hostname mapping
output "all_k8s_nodes" {
  description = "Complete list of K8s nodes với names và IPs"
  value = concat(
    # Master nodes
    [for i, instance in module.k8s_masters :
      "${local.name_prefix}-master-${i + 1}: ${instance.private_ip}"
    ],
    # Worker nodes
    [for i, instance in module.k8s_workers :
      "${local.name_prefix}-worker-${i + 1}: ${instance.private_ip}"
    ]
  )
}

# ===========================================
# LOAD BALANCER OUTPUTS
# ===========================================

# ALB information
output "alb_info" {
  description = "Application Load Balancer details"
  value = {
    dns_name          = module.alb.dns_name
    arn               = module.alb.arn
    hosted_zone_id    = module.alb.zone_id
    target_group_arns = [for tg_key, tg_value in module.alb.target_groups : tg_value.arn]
  }
}

# ALB endpoint cho external access
output "cluster_endpoint" {
  description = "Public endpoint để access K8s cluster qua ALB"
  value       = var.ssl_certificate_arn != null ? "https://${module.alb.dns_name}" : "http://${module.alb.dns_name}"
}

# ===========================================
# STORAGE OUTPUTS  
# ===========================================

# S3 bucket cho ALB logs
output "alb_logs_bucket" {
  description = "S3 bucket information cho ALB access logs"
  value = {
    name = module.alb_logs_bucket.s3_bucket_id
    arn  = module.alb_logs_bucket.s3_bucket_arn
  }
}

# ===========================================
# ACCESS & MANAGEMENT OUTPUTS
# ===========================================

# SSH key information
output "ssh_access" {
  description = "SSH access configuration"
  value = {
    key_name    = aws_key_pair.k8s_key.key_name
    key_pair_id = aws_key_pair.k8s_key.key_pair_id
    note        = "Instances are in private subnets - use Session Manager or bastion host"
  }
}

# AWS SSM connection commands cho management
output "ssm_commands" {
  description = "AWS Systems Manager session commands"
  value = {
    master_1 = "aws ssm start-session --target ${module.k8s_masters[0].id} --region ${var.region}"
    worker_1 = "aws ssm start-session --target ${module.k8s_workers[0].id} --region ${var.region}"
    note     = "Install Session Manager plugin: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"
  }
}

# ===========================================
# CLUSTER SUMMARY
# ===========================================

# Quick reference cho common information
output "cluster_summary" {
  description = "K8s cluster overview và quick reference"
  value = {
    cluster_name       = local.k8s_cluster_name
    region             = var.region
    environment        = var.environment
    vpc_cidr           = var.vpc_cidr
    total_instances    = var.master_count + var.worker_count
    master_count       = var.master_count
    worker_count       = var.worker_count
    kubernetes_version = var.kubernetes_version
    first_master_ip    = module.k8s_masters[0].private_ip
    alb_dns_name       = module.alb.dns_name
  }
}
