# dev/data.tf 


data "aws_ami" "ubuntu" {
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

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}


resource "tls_private_key" "this" {
  algorithm = "RSA"
}

resource "aws_key_pair" "key" {
  public_key = tls_private_key.this.public_key_openssh
  key_name   = "${local.name_prefix}-ssh-key"
}

resource "local_sensitive_file" "key" {
  filename = "./${aws_key_pair.key.key_name}.pem"
  content  = tls_private_key.this.private_key_openssh
}
