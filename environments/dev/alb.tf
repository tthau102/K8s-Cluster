# environments/dev/alb.tf

# =============================================================================
# APPLICATION LOAD BALANCER
# Internet-facing ALB cho Kubernetes Ingress traffic
# =============================================================================

# ALB Module cho external traffic đến K8s cluster
# Mục đích: Distribute traffic từ internet đến K8s NodePort services
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name               = "${local.name_prefix}-alb"
  load_balancer_type = "application"

  # Network configuration
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets # Public subnets cho internet access

  # Security
  security_groups = [module.alb_sg.security_group_id]

  # Deletion protection - tắt cho dev environment
  enable_deletion_protection = var.enable_deletion_protection

  # Access logs configuration
  access_logs = {
    bucket  = module.alb_logs_bucket.s3_bucket_id
    prefix  = "alb-access-logs"
    enabled = true
  }

  # ===========================================
  # LISTENERS CONFIGURATION
  # ===========================================

  listeners = {
    # HTTP Listener
    http = {
      port     = 80
      protocol = "HTTP"

      # Redirect HTTP to HTTPS nếu có SSL certificate, nếu không thì forward
      default_actions = var.ssl_certificate_arn != null ? [
        {
          type = "redirect"
          redirect = {
            port        = "443"
            protocol    = "HTTPS"
            status_code = "HTTP_301"
          }
        }
        ] : [
        {
          type             = "forward"
          target_group_key = "k8s_ingress"
        }
      ]
    }

    # HTTPS Listener (chỉ khi có SSL certificate)  
    https = var.ssl_certificate_arn != null ? {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      certificate_arn = var.ssl_certificate_arn

      default_actions = [
        {
          type             = "forward"
          target_group_key = "k8s_ingress"
        }
      ]
    } : {}
  }

  # ===========================================
  # TARGET GROUPS CONFIGURATION  
  # ===========================================

  target_groups = {
    # Target group cho K8s Ingress Controller NodePort
    k8s_ingress = {
      name                 = "${local.name_prefix}-k8s-ingress"
      port                 = 30080 # NGINX Ingress Controller default NodePort
      protocol             = "HTTP"
      target_type          = "instance"
      deregistration_delay = 30 # Faster rolling updates

      # Health check configuration
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        unhealthy_threshold = 3
        timeout             = 10
        interval            = 30
        path                = "/healthz" # NGINX Ingress health endpoint
        matcher             = "200,404"  # Accept 404 for default backend
        port                = "30080"
        protocol            = "HTTP"
      }

      # Target group targets - tất cả worker nodes
      targets = {
        for i, instance in module.k8s_workers : "worker-${i + 1}" => {
          target_id = instance.id
          port      = 30080
        }
      }

      # Target group attributes
      target_group_health_check_grace_period_seconds = 60
      target_health_state_unhealthy_draining_enabled = true

      tags = {
        Name      = "${local.name_prefix}-k8s-ingress-tg"
        Component = "load-balancer"
        Purpose   = "k8s-ingress"
      }
    }

    # Optional: HTTPS target group cho backend SSL
    k8s_ingress_ssl = var.ssl_certificate_arn != null ? {
      name                 = "${local.name_prefix}-k8s-ingress-ssl"
      port                 = 30443 # NGINX Ingress HTTPS NodePort
      protocol             = "HTTPS"
      target_type          = "instance"
      deregistration_delay = 30

      health_check = {
        enabled             = true
        healthy_threshold   = 2
        unhealthy_threshold = 3
        timeout             = 10
        interval            = 30
        path                = "/healthz"
        matcher             = "200,404"
        port                = "30443"
        protocol            = "HTTPS"
      }

      targets = {
        for i, instance in module.k8s_workers : "worker-ssl-${i + 1}" => {
          target_id = instance.id
          port      = 30443
        }
      }

      tags = {
        Name      = "${local.name_prefix}-k8s-ingress-ssl-tg"
        Component = "load-balancer"
        Purpose   = "k8s-ingress-ssl"
      }
    } : null
  }

  # ===========================================
  # TAGS
  # ===========================================

  tags = merge(local.tags, {
    Name      = "${local.name_prefix}-alb"
    Component = "load-balancer"
    Purpose   = "k8s-ingress"
    Tier      = "web"

    # AWS Load Balancer Controller tags
    "kubernetes.io/cluster/${local.k8s_cluster_name}" = "owned"
    "kubernetes.io/service-name"                      = "ingress-nginx/ingress-nginx-controller"
  })
}
