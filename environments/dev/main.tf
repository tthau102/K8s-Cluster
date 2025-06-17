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
