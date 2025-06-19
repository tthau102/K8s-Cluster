# environments/dev/bastion-host.tf

# Data source for Ubuntu AMI
data "aws_ami" "bastion_ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for Bastion
resource "aws_security_group" "bastion" {
  name        = "${var.owner}-${var.project}-${var.environment}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = module.vpc.vpc_id

  # SSH access from specific IPs (customize as needed)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Change to your IP for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.owner}-${var.project}-${var.environment}-bastion-sg"
  })
}

# Bastion Host Instance
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.bastion_ubuntu.id
  instance_type               = "t3.micro"
  key_name                    = "${var.owner}-${var.project}-${var.environment}-key"
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  subnet_id                   = module.vpc.public_subnet_ids[0]
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size          = 8
    delete_on_termination = true
    encrypted            = true

    tags = merge(local.tags, {
      Name = "${var.owner}-${var.project}-${var.environment}-bastion-root"
    })
  }

  tags = merge(local.tags, {
    Name = "${var.owner}-${var.project}-${var.environment}-bastion"
    Type = "bastion"
  })
}

# Output bastion information
output "bastion_public_ip" {
  description = "Public IP of bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.bastion.public_ip}"
}