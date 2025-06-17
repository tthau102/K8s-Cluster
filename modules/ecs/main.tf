# modules/ecs/main.tf

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#################
# ECS Cluster
#################
resource "aws_ecs_cluster" "main" {
  name = "${var.project}-${var.environment}-cluster"
  tags = local.tags
}

#################
# Load Balancer
#################
resource "aws_lb" "main" {
  name                       = "${var.project}-${var.environment}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_sg_id]
  subnets                    = var.public_subnet_ids
  enable_deletion_protection = false

  tags = local.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

#################
# IAM Roles - THIS IS THE SECTION WE NEED TO FIX
#################
resource "aws_iam_role" "task_execution" {
  name = "${var.project}-${var.environment}-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role" "task_role" {
  name = "${var.project}-${var.environment}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

# Base execution role policy
resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional permissions for SSM, KMS etc.
resource "aws_iam_role_policy" "task_execution_ssm" {
  name = "${var.project}-${var.environment}-task-execution-ssm"
  role = aws_iam_role.task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:DescribeParameters"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.project}/${var.environment}/*",
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.project}-${var.environment}-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = [
          "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.project}/${var.environment}/*"
        ]
      }
    ]
  })
}

#################
# Target Groups
#################
resource "aws_lb_target_group" "services" {
  for_each = var.services

  name                 = "${var.project}-${var.environment}-${each.key}-tg"
  port                 = each.value.container_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 15

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
    path                = each.value.health_check_path
    port                = each.value.container_port
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

#################
# Listener Rules
#################
resource "aws_lb_listener_rule" "backend" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.services["backend"].arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_lb_listener_rule" "frontend" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.services["frontend"].arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

#################
# ECS Tasks & Services
#################
resource "aws_ecs_task_definition" "services" {
  for_each = var.services

  family                   = "${var.project}-${var.environment}-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([{
    name            = each.value.container_name
    image           = each.value.container_image
    essential       = true
    security_groups = [var.ecs_tasks_sg_id]

    healthCheck = {
      command = [
        "CMD-SHELL",
        "wget --no-verbose --tries=1 --spider http://localhost:${each.value.container_port}/health || exit 1"
      ]
      interval    = 15
      timeout     = 5
      retries     = 3
      startPeriod = 30
    }

    portMappings = [{
      containerPort = each.value.container_port
      protocol      = "tcp"
    }]

    environment = each.value.environment
    secrets     = each.value.secrets

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.project}-${var.environment}"
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = each.key
      }
    }
  }])

  tags = local.tags
}

resource "aws_ecs_service" "services" {
  for_each = var.services

  name            = "${var.project}-${var.environment}-${each.key}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.services[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  force_new_deployment               = true

  deployment_circuit_breaker {
    enable   = false
    rollback = false
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_tasks_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.services[each.key].arn
    container_name   = each.value.container_name
    container_port   = each.value.container_port
  }

  depends_on = [aws_lb_listener.http]

  tags = local.tags
}

#################
# CloudWatch Logs
#################
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project}-${var.environment}"
  retention_in_days = 30
  tags              = local.tags
}

#################
# S3 Bucket
#################
resource "aws_s3_bucket" "videos" {
  bucket        = "${var.project}-${var.environment}-videos"
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_policy" "videos" {
  bucket = aws_s3_bucket.videos.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECSTasksS3Access"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.task_role.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.videos.arn}/*",
          aws_s3_bucket.videos.arn
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "videos" {
  bucket = aws_s3_bucket.videos.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#################
# Task Role Policies
#################
resource "aws_iam_role_policy" "task_role_s3" {
  name = "${var.project}-${var.environment}-task-s3-policy"
  role = aws_iam_role.task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ]
      Resource = [
        "${aws_s3_bucket.videos.arn}/*",
        aws_s3_bucket.videos.arn
      ]
    }]
  })
}



