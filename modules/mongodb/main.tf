# modules/mongodb/main.tf

# Data source for Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical owner ID
}
# # Security Group for MongoDB // Moved to modules/security/main.tf
# resource "aws_security_group" "mongodb" {
#   name        = "${var.project}-${var.environment}-mongodb-sg"
#   description = "Security group for MongoDB"
#   vpc_id      = var.vpc_id

#   ingress {
#     from_port       = 27017
#     to_port         = 27017
#     protocol        = "tcp"
#     security_groups = [var.security_group_id]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = local.tags
# }

resource "aws_instance" "mongodb" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [var.mongodb_sg_id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update && apt-get install -y gnupg
              wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add -
              echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
              apt-get update
              apt-get install -y mongodb-org
              sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf
              systemctl start mongod
              systemctl enable mongod
              EOF

  tags = merge(local.tags, {
    Name = "${var.project}-${var.environment}-mongodb"
  })
}

resource "aws_ssm_parameter" "mongodb_connection_string" {
  name        = "/${var.project}/${var.environment}/MONGODB_URI"
  description = "MongoDB Connection String"
  type        = "SecureString"
  value       = "mongodb://${aws_instance.mongodb.private_ip}:27017/movie-streaming"

  tags = local.tags
}
