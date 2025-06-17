# modules/security/main.tf
resource "aws_security_group" "alb" {
  name   = "${var.project}-${var.environment}-alb-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_tasks" {
  name   = "${var.project}-${var.environment}-ecs-tasks-sg"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = toset(var.container_ports)
    content {
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.alb.id]
    }
  }
  # Allow internal communication
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "mongodb" {
  name   = "${var.project}-${var.environment}-mongodb-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "ecs_tasks_sg_id" {
  value = aws_security_group.ecs_tasks.id
}

output "mongodb_sg_id" {
  value = aws_security_group.mongodb.id
}
