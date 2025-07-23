# /dev/7.lb.tf


variable "lb_config" {
  type = object({
    name          = string
    instance_type = string
  })
}

module "loadbalancer" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.0.2"

  name = "${local.name_prefix}-${var.lb_config.name}"

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.lb_config.instance_type
  key_name      = aws_key_pair.key.key_name

  monitoring = true

  create_security_group       = false
  vpc_security_group_ids      = [module.public_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[1]
  associate_public_ip_address = true

  enable_volume_tags = false
  root_block_device = {
    type                  = "gp3"
    size                  = 30
    delete_on_termination = true
    encrypted             = true
    tags = {
      Name = "${local.name_prefix}-${var.lb_config.name}-root"
    }
  }

  ebs_volumes = {
    "/dev/sdf" = {
      type                  = "gp3"
      size                  = 20
      delete_on_termination = true
      encrypted             = true
    }
  }
}
