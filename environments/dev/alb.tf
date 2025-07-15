# environments/dev/alb.tf

# =============================================================================
# APPLICATION LOAD BALANCER
# Internet-facing ALB cho K8s ingress traffic
# =============================================================================

# Random ID cho unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Application Load Balancer
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = "${local.name_prefix}-alb"

  # ALB configuration
  load_balancer_type = "application"
  internal           = false # Internet-facing

  # Network configuration
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.alb_sg.security_group_id]

  # # Access logs configuration
  # access_logs = {
  #   bucket  = module.alb_logs_s3.s3_bucket_id
  #   prefix  = "alb-access-logs"
  #   enabled = true
  # }

  # Deletion protection
  enable_deletion_protection = var.enable_deletion_protection

  # Target Groups
  target_groups = [
    {
      name                 = "${local.name_prefix}-k8s-ingress"
      backend_protocol     = "HTTP"
      backend_port         = 30080 # NodePort cho NGINX Ingress Controller
      target_type          = "instance"
      deregistration_delay = 10

      # Health check configuration
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30
        matcher             = "200,404"
        path                = "/healthz"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      # Target instances - all worker nodes
      targets = {
        for i, instance in module.k8s_workers : "worker-${i + 1}" => {
          target_id = instance.id
          port      = 30080
        }
      }
    }
  ]

  # # HTTP Listener
  # http_tcp_listeners = [
  #   {
  #     port     = 80
  #     protocol = "HTTP"

  #     # Conditional action
  #     action_type = var.ssl_certificate_arn != null ? "redirect" : "forward"

  #     # HTTPS redirect (nếu có SSL cert)
  #     redirect = var.ssl_certificate_arn != null ? {
  #       port        = "443"
  #       protocol    = "HTTPS"
  #       status_code = "HTTP_301"
  #     } : null

  #     # Forward to target group (nếu không có SSL cert)
  #     target_group_index = var.ssl_certificate_arn != null ? null : 0
  #   }
  # ]

  # # HTTPS Listener (chỉ tạo nếu có SSL certificate)
  # https_listeners = var.ssl_certificate_arn != null ? [
  #   {
  #     port               = 443
  #     protocol           = "HTTPS"
  #     certificate_arn    = var.ssl_certificate_arn
  #     target_group_index = 0

  #     # SSL Policy
  #     ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"
  #   }
  # ] : []

  tags = merge(local.tags, {
    Name      = "${local.name_prefix}-alb"
    Component = "load-balancer"
    Type      = "application"
    Purpose   = "k8s-ingress"
  })

  # depends_on = [module.alb_logs_s3]
}
