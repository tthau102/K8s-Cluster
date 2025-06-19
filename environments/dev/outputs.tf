# environments/dev/outputs.tf

# ===========================================
# NETWORKING OUTPUTS
# ===========================================

output "vpc_info" {
  description = "VPC information"
  value = {
    id         = module.vpc.vpc_id
    cidr_block = module.vpc.vpc_cidr_block
    name       = "tth-k8s-pj-dev-vpc"
  }
}

output "subnets" {
  description = "Subnet information organized by type"
  value = {
    public = {
      ids    = module.vpc.public_subnet_ids
      cidrs  = module.vpc.public_subnet_cidrs
      count  = length(module.vpc.public_subnet_ids)
    }
    private = {
      ids    = module.vpc.private_subnet_ids  
      cidrs  = module.vpc.private_subnet_cidrs
      count  = length(module.vpc.private_subnet_ids)
    }
  }
}

output "network_gateways" {
  description = "Network gateway information"
  value = {
    internet_gateway_id = module.vpc.internet_gateway_id
    nat_gateway_ids     = module.vpc.nat_gateway_ids
    availability_zones  = module.vpc.availability_zones
  }
}

# ===========================================
# KUBERNETES CLUSTER OUTPUTS  
# ===========================================

output "k8s_master_nodes" {
  description = "Kubernetes master nodes information"
  value = {
    instance_ids  = module.ec2.master_instance_ids
    private_ips   = module.ec2.master_private_ips
    count         = length(module.ec2.master_instance_ids)
    instance_type = "t3.medium"
  }
}

output "k8s_worker_nodes" {
  description = "Kubernetes worker nodes information"  
  value = {
    instance_ids  = module.ec2.worker_instance_ids
    private_ips   = module.ec2.worker_private_ips
    count         = length(module.ec2.worker_instance_ids)
    instance_type = "t3.large"
  }
}

output "cluster_summary" {
  description = "Kubernetes cluster overview"
  value = module.ec2.cluster_info
}

# ===========================================
# SECURITY OUTPUTS
# ===========================================

output "security_groups" {
  description = "Security group IDs for different components"
  value = {
    k8s_master = module.security.k8s_master_sg_id
    k8s_worker = module.security.k8s_worker_sg_id
    alb        = module.security.alb_sg_id
  }
}

# ===========================================
# ACCESS & CONNECTION INFO
# ===========================================

output "ssh_access" {
  description = "SSH access information"
  value = {
    key_name = "tth-k8s-pj-dev-key"
    note     = "Instances are in private subnets - use Session Manager or bastion host"
  }
}

output "connection_commands" {
  description = "Useful connection commands"
  value = {
    ssm_master_1 = "aws ssm start-session --target ${module.ec2.master_instance_ids[0]} --region ap-southeast-5"
    ssm_worker_1 = "aws ssm start-session --target ${module.ec2.worker_instance_ids[0]} --region ap-southeast-5"
    init_cluster = "sudo /root/init-cluster.sh  # Run on master-1"
  }
}

# ===========================================
# QUICK REFERENCE
# ===========================================

output "quick_reference" {
  description = "Quick reference for common tasks"
  value = {
    region           = "ap-southeast-5"
    environment      = "dev"
    cluster_name     = "tth-k8s-pj-dev"
    total_instances  = length(module.ec2.master_instance_ids) + length(module.ec2.worker_instance_ids)
    first_master_ip  = module.ec2.master_private_ips[0]
  }
}