# dev/2.2.security-groups.tf



module "public_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${local.name_prefix}-public-sg"
  description = "Public SG"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "User-service ports"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Full access to VPC"
      cidr_blocks = var.vpc_cidr
    },
  ]

  egress_rules = ["all-all"]
}


module "master_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${local.name_prefix}-master-sg"
  description = "Master SG"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH"
      cidr_blocks = var.vpc_cidr
    },
    {
      from_port   = 6443
      to_port     = 6443
      protocol    = "tcp"
      description = "Kubernetes API server"
      cidr_blocks = var.vpc_cidr
    },
    {
      from_port   = 2379
      to_port     = 2380
      protocol    = "tcp"
      description = "etcd server client API"
      cidr_blocks = var.vpc_cidr
    },
    {
      from_port   = 10250
      to_port     = 10250
      protocol    = "tcp"
      description = "kubelet API"
      cidr_blocks = var.vpc_cidr
    },
    {
      from_port   = 10251
      to_port     = 10252
      protocol    = "tcp"
      description = "kube-scheduler & kube-controller-manager"
      cidr_blocks = var.vpc_cidr
    },
  ]

  ingress_with_source_security_group_id = [{
    from_port                = 0
    to_port                  = 65535
    protocol                 = "tcp"
    description              = "Inter-master communication"
    source_security_group_id = module.master_sg.security_group_id
  }]

  egress_rules = ["all-all"]
}


module "worker_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${local.name_prefix}-worker-sg"
  description = "Kubernetes Worker Security Group"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH access"
      cidr_blocks = var.vpc_cidr
    },
    {
      from_port   = 10250
      to_port     = 10250
      protocol    = "tcp"
      description = "kubelet API"
      cidr_blocks = var.vpc_cidr
    },
    {
      from_port   = 30000
      to_port     = 32767
      protocol    = "tcp"
      description = "NodePort Services"
      cidr_blocks = var.vpc_cidr
    },
    {
      from_port   = 8472
      to_port     = 8472
      protocol    = "udp"
      description = "Flannel VXLAN"
      cidr_blocks = var.vpc_cidr
    },
    {
      from_port   = 179
      to_port     = 179
      protocol    = "tcp"
      description = "Calico BGP"
      cidr_blocks = var.vpc_cidr
    },
    {
      from_port   = 4789
      to_port     = 4789
      protocol    = "udp"
      description = "Flannel VXLAN"
      cidr_blocks = var.vpc_cidr
    },
    # Calico IPIP
    {
      from_port   = 0
      to_port     = 0
      protocol    = "4" # IPIP protocol
      description = "Calico IPIP"
      cidr_blocks = var.vpc_cidr
    },
  ]

  # Allow communication from masters
  ingress_with_source_security_group_id = [
    {
      from_port                = 0
      to_port                  = 65535
      protocol                 = "tcp"
      description              = "From masters"
      source_security_group_id = module.master_sg.security_group_id
    },
    {
      from_port                = 0
      to_port                  = 65535
      protocol                 = "tcp"
      description              = "Inter-worker communication"
      source_security_group_id = module.worker_sg.security_group_id
    }
  ]

  egress_rules = ["all-all"]
}

