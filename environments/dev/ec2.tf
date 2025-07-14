# environments/dev/ec2.tf

# =============================================================================
# EC2 INSTANCES - KUBERNETES NODES
# Master nodes (control plane) và Worker nodes
# =============================================================================

# K8s Master Nodes - Control Plane
# Mục đích: Chạy API server, etcd, scheduler, controller-manager
module "k8s_masters" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  count = var.master_count

  name = "${local.name_prefix}-master-${count.index + 1}"

  # Instance configuration
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.master_instance_type
  key_name      = aws_key_pair.k8s_key.key_name

  # Monitoring enable cho CloudWatch metrics
  monitoring = true

  # Network configuration
  vpc_security_group_ids      = [module.k8s_master_sg.security_group_id]
  subnet_id                   = module.vpc.private_subnets[count.index % length(module.vpc.private_subnets)]
  associate_public_ip_address = false # Private instances cho security

  # IAM configuration - chỉ dùng managed policies
  create_iam_instance_profile = true
  iam_role_description        = "IAM role for K8s master nodes"
  iam_role_policies = {
    # Systems Manager access cho session management
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  # Storage configuration
  root_block_device = [
    {
      volume_type           = "gp3" # GP3 cho better performance/cost ratio
      volume_size           = 20    # 20GB cho OS và K8s binaries
      delete_on_termination = true  # Cleanup khi terminate
      encrypted             = true  # Encryption at rest
      # Remove tags từ đây để tránh conflict
    }
  ]

  # Volume tags separate
  volume_tags = {
    Name = "${local.name_prefix}-master-${count.index + 1}-root"
  }

  tags = merge(local.tags, {
    Type = "k8s-master"
    Role = "control-plane"

    # AWS Load Balancer Controller cần tag này
    "kubernetes.io/cluster/${local.k8s_cluster_name}" = "owned"

    Component = "compute"

    # Backup policy
    Backup = "required"
  })
}

# K8s Worker Nodes
# Mục đích: Chạy application pods, kubelet, kube-proxy
module "k8s_workers" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  count = var.worker_count

  name = "${local.name_prefix}-worker-${count.index + 1}"

  # Instance configuration
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.worker_instance_type
  key_name      = aws_key_pair.k8s_key.key_name

  # Monitoring enable
  monitoring = true

  # Network configuration
  vpc_security_group_ids      = [module.k8s_worker_sg.security_group_id]
  subnet_id                   = module.vpc.private_subnets[count.index % length(module.vpc.private_subnets)]
  associate_public_ip_address = false # Private instances

  # IAM configuration - chỉ dùng managed policies
  create_iam_instance_profile = true
  iam_role_description        = "IAM role for K8s worker nodes"
  iam_role_policies = {
    # Systems Manager access
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  # Storage configuration - workers cần storage lớn hơn cho pods
  root_block_device = [
    {
      volume_type           = "gp3" # GP3 performance
      volume_size           = 30    # 30GB cho pods, images, logs
      delete_on_termination = true  # Cleanup
      encrypted             = true  # Security
      # Remove tags từ đây để tránh conflict
    }
  ]

  # Volume tags separate
  volume_tags = {
    Name = "${local.name_prefix}-worker-${count.index + 1}-root"
  }

  # User data script để install K8s (nếu cần)
  # user_data = base64encode(templatefile("${path.module}/user-data.sh", {
  #   kubernetes_version = var.kubernetes_version
  #   containerd_version = var.containerd_version
  #   node_type         = "worker"
  # }))

  tags = merge(local.tags, {
    Type = "k8s-worker"
    Role = "worker"

    # AWS Load Balancer Controller
    "kubernetes.io/cluster/${local.k8s_cluster_name}" = "owned"

    Component = "compute"

    # Backup policy
    Backup = "required"
  })
}

# Inline policies cho master nodes - separate resources
resource "aws_iam_role_policy" "k8s_master_policy" {
  count = var.master_count

  name = "${local.name_prefix}-master-${count.index + 1}-policy"
  role = module.k8s_masters[count.index].iam_role_name

  policy = local.k8s_master_policy
}

# Inline policies cho worker nodes - separate resources  
resource "aws_iam_role_policy" "k8s_worker_policy" {
  count = var.worker_count

  name = "${local.name_prefix}-worker-${count.index + 1}-policy"
  role = module.k8s_workers[count.index].iam_role_name

  policy = local.k8s_worker_policy
}
