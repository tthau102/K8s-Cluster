# environments/dev/main.tf
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr                 = var.vpc_cidr
  availability_zones_count = var.availability_zones_count
  enable_nat_gateway       = var.enable_nat_gateway
  enable_vpc_endpoints     = var.enable_vpc_endpoints

  # additional_tags = {
  #   Backup            = "required"
  #   KubernetesCluster = "dev-k8s"
  #   Tier              = "infrastructure"
  # }
}

module "security" {
  source = "../../modules/security"
  
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = module.vpc.vpc_cidr_block
  
  additional_tags = {
    Component = "security"
  }
}