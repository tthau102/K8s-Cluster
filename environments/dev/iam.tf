# environments/dev/iam.tf

# =============================================================================
# IAM ROLES AND POLICIES
# Định nghĩa permissions cho K8s nodes và AWS integrations
# =============================================================================

# EC2 Key Pair cho SSH access
# Mục đích: Secure access đến instances cho troubleshooting
resource "aws_key_pair" "k8s_key" {
  key_name   = "${local.name_prefix}-key"
  public_key = file("~/.ssh/id_rsa.pub")

  tags = merge(local.tags, {
    Name      = "${local.name_prefix}-key"
    Component = "security"
    Purpose   = "ssh-access"
  })
}

# IAM policies cho Master nodes
# Mục đích: AWS cloud provider integration, ELB management, EBS volumes
locals {
  k8s_master_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # EC2 permissions cho node discovery và management
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVolumes",
          "ec2:DescribeAvailabilityZones",

          # EBS volume management cho persistent volumes
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyVolume",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:DescribeSnapshots",

          # Tagging cho resource management
          "ec2:CreateTags",
          "ec2:DescribeTags",

          # Security group management cho services
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",

          # Route table management cho networking
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:ModifyInstanceAttribute",

          # ELB/ALB management cho LoadBalancer services
          "elasticloadbalancing:*",

          # Auto Scaling integration
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })

  # Worker node policy - minimal permissions
  k8s_worker_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # Instance metadata access
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",

          # ECR access cho pulling container images
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
