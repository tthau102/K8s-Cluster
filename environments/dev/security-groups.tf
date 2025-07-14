# environments/dev/security-groups.tf

# =============================================================================
# SECURITY GROUPS
# Network access control cho các components của K8s cluster
# =============================================================================

# Security Group cho K8s Master Nodes
# Mục đích: Kiểm soát traffic đến control plane components
module "k8s_master_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name_prefix}-master-sg"
  description = "Security group for Kubernetes master nodes"
  vpc_id      = module.vpc.vpc_id

  # Ingress rules với CIDR blocks - traffic từ VPC
  ingress_with_cidr_blocks = [
    {
      from_port   = 6443
      to_port     = 6443
      protocol    = "tcp"
      description = "K8s API Server - kubectl, kubelet connections"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 10250
      to_port     = 10250
      protocol    = "tcp"
      description = "Kubelet API - kube-apiserver access"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH access for management"
      cidr_blocks = module.vpc.vpc_cidr_block
    }
  ]

  # Ingress rules với self-reference - master-to-master communication
  ingress_with_self = [
    {
      from_port   = 2379
      to_port     = 2380
      protocol    = "tcp"
      description = "etcd server client API and peer communication"
    },
    {
      from_port   = 10251
      to_port     = 10251
      protocol    = "tcp"
      description = "kube-scheduler health check"
    },
    {
      from_port   = 10252
      to_port     = 10252
      protocol    = "tcp"
      description = "kube-controller-manager health check"
    }
  ]

  # Allow all outbound traffic
  egress_rules = ["all-all"]

  tags = merge(local.tags, {
    Name      = "${local.name_prefix}-master-sg"
    Component = "security"
    Type      = "k8s-master"
    Purpose   = "control-plane-security"
  })
}

# Security Group cho K8s Worker Nodes
# Mục đích: Kiểm soát traffic đến worker nodes và pod networking
module "k8s_worker_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name_prefix}-worker-sg"
  description = "Security group for Kubernetes worker nodes"
  vpc_id      = module.vpc.vpc_id

  # Traffic từ master nodes
  ingress_with_source_security_group_id = [
    {
      from_port                = 10250
      to_port                  = 10250
      protocol                 = "tcp"
      description              = "Kubelet API - master nodes monitoring"
      source_security_group_id = module.k8s_master_sg.security_group_id
    },
    {
      from_port                = 6443
      to_port                  = 6443
      protocol                 = "tcp"
      description              = "K8s API proxy from masters"
      source_security_group_id = module.k8s_master_sg.security_group_id
    }
  ]

  # Traffic từ VPC CIDR
  ingress_with_cidr_blocks = [
    {
      from_port   = 30000
      to_port     = 32767
      protocol    = "tcp"
      description = "NodePort Services - external access to apps"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH access for management"
      cidr_blocks = module.vpc.vpc_cidr_block
    }
  ]

  # Worker-to-worker communication cho pod networking
  ingress_with_self = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "Pod-to-pod TCP communication"
    },
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "udp"
      description = "Pod-to-pod UDP communication (CNI overlay)"
    }
  ]

  # Allow all outbound traffic
  egress_rules = ["all-all"]

  tags = merge(local.tags, {
    Name      = "${local.name_prefix}-worker-sg"
    Component = "security"
    Type      = "k8s-worker"
    Purpose   = "worker-node-security"
  })
}

# Security Group cho Application Load Balancer
# Mục đích: Internet-facing load balancer cho K8s ingress
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  # Internet traffic cho web applications
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP traffic from internet"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS traffic from internet"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  # Outbound đến worker nodes cho health checks và traffic forwarding
  egress_with_source_security_group_id = [
    {
      from_port                = 30000
      to_port                  = 32767
      protocol                 = "tcp"
      description              = "NodePort range for ingress controllers"
      source_security_group_id = module.k8s_worker_sg.security_group_id
    }
  ]

  tags = merge(local.tags, {
    Name      = "${local.name_prefix}-alb-sg"
    Component = "security"
    Type      = "load-balancer"
    Purpose   = "ingress-security"
  })
}
