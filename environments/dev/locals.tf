# environments/dev/locals.tf

# =============================================================================
# LOCAL VALUES
# Định nghĩa các giá trị được sử dụng nhiều lần trong configuration
# =============================================================================

locals {
  # Prefix chuẩn cho tất cả resources: owner-project-environment
  # Mục đích: Đảm bảo naming consistency và resource identification
  name_prefix = "${var.owner}-${var.project}-${var.environment}"

  # Danh sách AZs sẽ sử dụng, giới hạn theo availability_zones_count
  # Mục đích: Tối ưu cost bằng cách chỉ sử dụng số AZs cần thiết
  azs = slice(data.aws_availability_zones.available.names, 0, var.availability_zones_count)

  # Public subnets CIDR calculation
  # Mỗi AZ có 1 public subnet với /24 (256 IPs)
  # Mục đích: Subnet cho ALB, NAT Gateway, Bastion hosts
  public_subnets = [
    for i in range(var.availability_zones_count) :
    cidrsubnet(var.vpc_cidr, 8, i)
  ]

  # Private subnets CIDR calculation  
  # Mỗi AZ có 1 private subnet với /24, offset +10 để tránh conflict
  # Mục đích: Subnet cho K8s nodes (masters + workers)
  private_subnets = [
    for i in range(var.availability_zones_count) :
    cidrsubnet(var.vpc_cidr, 8, i + 10)
  ]

  # Common tags cho tất cả resources
  # Mục đích: Resource management, cost tracking, compliance
  tags = {
    Project     = var.project             # Phân loại theo project
    Environment = var.environment         # Dev/staging/prod environment
    Owner       = var.owner               # Ownership tracking
    Managed_by  = "terraform"             # Infrastructure as Code indicator
    Created_by  = "terraform-aws-modules" # Indicate using official modules
  }

  # Kubernetes cluster identifier
  # Mục đích: AWS Load Balancer Controller và Cloud Provider cần tag này
  k8s_cluster_name = local.name_prefix
}
