# dev/3.1.servers.tf 


variable "servers" {
  description = "Danh sách cấu hình các instance"
  type = list(object({
    name          = string
    instance_type = string
  }))
}

locals {
  servers_map = { for inst in var.servers : inst.name => inst }
}

module "servers" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.0.2"

  for_each = local.servers_map
  name     = "${local.name_prefix}-${each.key}"

  ami           = data.aws_ami.ubuntu.id
  instance_type = each.value.instance_type
  key_name      = aws_key_pair.key.key_name

  monitoring = true

  vpc_security_group_ids      = [module.public_sg.security_group_id]
  subnet_id                   = module.vpc.private_subnets[0]
  associate_public_ip_address = false
  create_security_group       = false

  root_block_device = {
    type                  = "gp3"
    size                  = 30
    delete_on_termination = true
    encrypted             = true
    tags = {
      Name = "${local.name_prefix}-${each.key}-root"
    }
  }

  enable_volume_tags = false
  ebs_volumes = merge(
    {
      "/dev/sdf" = {
        type                  = "gp3"
        size                  = 20
        delete_on_termination = true
        encrypted             = true
      }
    },
    each.key == "rancher" ? {
      "/dev/sdg" = {
        type                  = "gp3"
        size                  = 40
        delete_on_termination = true
        encrypted             = true
      }
    } : {}
  )
}






