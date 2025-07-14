# environments/dev/vpc.tf

# =============================================================================
# VPC & NETWORKING INFRASTRUCTURE
# Tạo network foundation cho Kubernetes cluster
# =============================================================================

# VPC Module - Core networking foundation
# Mục đích: Tạo isolated network environment cho K8s cluster
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  # Basic VPC configuration
  name = "${local.name_prefix}-vpc"
  cidr = var.vpc_cidr

  # Multi-AZ deployment cho high availability
  azs             = local.azs
  public_subnets  = local.public_subnets  # Cho ALB, NAT Gateway
  private_subnets = local.private_subnets # Cho K8s nodes

  # NAT Gateway configuration
  # enable_nat_gateway: Cho phép private subnets truy cập internet
  # single_nat_gateway: Cost optimization - dùng 1 NAT cho tất cả AZs
  enable_nat_gateway = var.enable_nat_gateway
  enable_vpn_gateway = false
  single_nat_gateway = true # Cost optimization

  # DNS settings - bắt buộc cho Kubernetes
  enable_dns_hostnames = true # Cho phép EC2 có public DNS names
  enable_dns_support   = true # Enable DNS resolution trong VPC

  # VPC Endpoints - giảm data transfer costs và tăng security
  # Note: Endpoints sẽ được tạo separately nếu cần

  # Subnet tagging cho AWS Load Balancer Controller
  # kubernetes.io/role/elb: Public subnets cho external load balancers
  public_subnet_tags = {
    "kubernetes.io/role/elb"                          = "1"
    "kubernetes.io/cluster/${local.k8s_cluster_name}" = "shared"
    Type                                              = "public"
  }

  # kubernetes.io/role/internal-elb: Private subnets cho internal load balancers
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                 = "1"
    "kubernetes.io/cluster/${local.k8s_cluster_name}" = "shared"
    Type                                              = "private"
  }

  # Resource tags
  tags = merge(local.tags, {
    Backup            = "required"       # Backup policy indicator
    KubernetesCluster = "dev-k8s"        # K8s cluster identifier
    Tier              = "infrastructure" # Infrastructure layer
  })
}
