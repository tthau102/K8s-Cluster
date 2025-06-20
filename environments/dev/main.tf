# environments/dev/main.tf
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr                 = var.vpc_cidr
  availability_zones_count = var.availability_zones_count
  enable_nat_gateway       = var.enable_nat_gateway
  enable_vpc_endpoints     = var.enable_vpc_endpoints

  additional_tags = {
    Backup            = "required"
    KubernetesCluster = "dev-k8s"
    Tier              = "infrastructure"
  }
}

module "security" {
  source = "../../modules/security"

  vpc_id   = module.vpc.vpc_id
  vpc_cidr = module.vpc.vpc_cidr_block

  additional_tags = {
    Component = "security"
  }
}

module "ec2" {
  source = "../../modules/ec2"

  # THÊM CÁC VARIABLES THIẾU
  master_count         = var.master_count
  worker_count         = var.worker_count
  master_instance_type = var.master_instance_type
  worker_instance_type = var.worker_instance_type
  kubernetes_version   = var.kubernetes_version
  containerd_version   = var.containerd_version

  # Variables đã có
  public_key               = file("~/.ssh/id_rsa.pub")
  private_subnet_ids       = module.vpc.private_subnet_ids
  master_security_group_id = module.security.k8s_master_sg_id
  worker_security_group_id = module.security.k8s_worker_sg_id

  additional_tags = {
    Component = "compute"
  }
}


module "k8s_cluster" {
  source = "../../modules/k8s-cluster"

  cluster_name = "tth-k8s-cluster"

  master_instances = [
    for i, ip in module.ec2.master_private_ips : {
      private_ip = ip
      id         = module.ec2.master_instance_ids[i]
    }
  ]

  worker_instances = [
    for i, ip in module.ec2.worker_private_ips : {
      private_ip = ip
      id         = module.ec2.worker_instance_ids[i]
    }
  ]

  bastion_ip           = module.ec2.bastion_public_ip
  ssh_private_key_path = "~/.ssh/id_rsa"
  kube_version         = "1.31.0"
}
