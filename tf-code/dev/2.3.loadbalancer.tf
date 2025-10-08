# /dev/2.3.loadbalancer.tf


variable "lb_config" {
  type = list(object({
    name          = string
    instance_type = string
  }))
}

locals {
  lb_map = { for i in var.lb_config : i.name => i }
}

module "loadbalancer" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.0.2"

  for_each = local.lb_map
  name     = "${local.name_prefix}-${each.key}"

  ami           = var.aws_ami
  instance_type = each.value.instance_type
  key_name      = aws_key_pair.key.key_name

  monitoring = true

  create_security_group       = false
  vpc_security_group_ids      = [module.public_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true

  enable_volume_tags = false
  root_block_device = {
    type                  = "gp3"
    size                  = 30
    delete_on_termination = true
    encrypted             = true
    tags = {
      Name = "${local.name_prefix}-${each.key}-root"
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
