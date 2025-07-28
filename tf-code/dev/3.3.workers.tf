# dev/3.3.workers.tf



variable "worker_count" {
  type = number
}

variable "worker_instance_type" {
  type = string
}

module "k8s_workers" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.0.2"

  count = var.worker_count

  name = "${local.name_prefix}-worker-0${count.index + 1}"

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.worker_instance_type
  key_name      = aws_key_pair.key.key_name

  monitoring = true

  create_security_group       = false
  vpc_security_group_ids      = [module.worker_sg.security_group_id]
  subnet_id                   = module.vpc.private_subnets[count.index % length(module.vpc.private_subnets)]
  associate_public_ip_address = false

  source_dest_check = false

  enable_volume_tags = false
  root_block_device = {
    type = "gp3"
    size = 30
    # delete_on_termination = true
    encrypted = true
    tags = {
      Name = "${local.name_prefix}-worker-${count.index + 1}-root"
    }
  }

  ebs_volumes = {
    "/dev/sdf" = {
      type = "gp3"
      size = 20
      # delete_on_termination = true
      encrypted = true
    }
  }
}




