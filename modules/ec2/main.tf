# modules/ec2/main.tf
# Data source for Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Key Pair for SSH access
resource "aws_key_pair" "k8s_key" {
  key_name   = "${local.name_prefix}-key"
  public_key = var.public_key

  tags = merge(var.additional_tags, {
    Name = "${local.name_prefix}-key"
  })
}

# Master Nodes
resource "aws_instance" "master" {
  count                  = var.master_count
  ami                   = data.aws_ami.ubuntu.id
  instance_type         = var.master_instance_type
  key_name              = aws_key_pair.k8s_key.key_name
  vpc_security_group_ids = [var.master_security_group_id]
  subnet_id             = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  iam_instance_profile  = aws_iam_instance_profile.k8s_master.name

  root_block_device {
    volume_type           = "gp3"
    volume_size          = 20
    delete_on_termination = true
    encrypted            = true

    tags = merge(var.additional_tags, {
      Name = "${local.name_prefix}-master-${count.index + 1}-root"
    })
  }

  tags = merge(var.additional_tags, {
    Name = "${local.name_prefix}-master-${count.index + 1}"
    Type = "k8s-master"
    Role = "control-plane"
    "kubernetes.io/cluster/${local.name_prefix}" = "owned"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Worker Nodes
resource "aws_instance" "worker" {
  count                  = var.worker_count
  ami                   = data.aws_ami.ubuntu.id
  instance_type         = var.worker_instance_type
  key_name              = aws_key_pair.k8s_key.key_name
  vpc_security_group_ids = [var.worker_security_group_id]
  subnet_id             = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  iam_instance_profile  = aws_iam_instance_profile.k8s_worker.name

  root_block_device {
    volume_type           = "gp3"
    volume_size          = 30
    delete_on_termination = true
    encrypted            = true

    tags = merge(var.additional_tags, {
      Name = "${local.name_prefix}-worker-${count.index + 1}-root"
    })
  }

  tags = merge(var.additional_tags, {
    Name = "${local.name_prefix}-worker-${count.index + 1}"
    Type = "k8s-worker"
    Role = "worker"
    "kubernetes.io/cluster/${local.name_prefix}" = "owned"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# IAM Role for Master Nodes
resource "aws_iam_role" "k8s_master" {
  name = "${local.name_prefix}-master-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.additional_tags, {
    Name = "${local.name_prefix}-master-role"
  })
}

# IAM Role for Worker Nodes
resource "aws_iam_role" "k8s_worker" {
  name = "${local.name_prefix}-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.additional_tags, {
    Name = "${local.name_prefix}-worker-role"
  })
}

# IAM Policies for Master Nodes
resource "aws_iam_role_policy" "k8s_master_policy" {
  name = "${local.name_prefix}-master-policy"
  role = aws_iam_role.k8s_master.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVolumes",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:ModifyInstanceAttribute",
          "ec2:ModifyVolume",
          "ec2:AttachVolume",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteVolume",
          "ec2:DetachVolume",
          "ec2:RevokeSecurityGroupIngress",
          "elasticloadbalancing:*",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Policies for Worker Nodes
resource "aws_iam_role_policy" "k8s_worker_policy" {
  name = "${local.name_prefix}-worker-policy"
  role = aws_iam_role.k8s_worker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# Instance Profiles
resource "aws_iam_instance_profile" "k8s_master" {
  name = "${local.name_prefix}-master-profile"
  role = aws_iam_role.k8s_master.name

  tags = merge(var.additional_tags, {
    Name = "${local.name_prefix}-master-profile"
  })
}

resource "aws_iam_instance_profile" "k8s_worker" {
  name = "${local.name_prefix}-worker-profile"
  role = aws_iam_role.k8s_worker.name

  tags = merge(var.additional_tags, {
    Name = "${local.name_prefix}-worker-profile"
  })
}

# Add to modules/ec2/main.tf

# Attach SSM policy to master role
resource "aws_iam_role_policy_attachment" "k8s_master_ssm" {
  role       = aws_iam_role.k8s_master.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach SSM policy to worker role  
resource "aws_iam_role_policy_attachment" "k8s_worker_ssm" {
  role       = aws_iam_role.k8s_worker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}