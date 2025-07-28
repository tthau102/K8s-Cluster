# dev/2.1.vpc.tf 


data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}


locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.availability_zones_count)

  public_subnets = [
    for i in range(var.availability_zones_count) :
    cidrsubnet(var.vpc_cidr, 8, i + 10)
  ]

  private_subnets = [
    for i in range(var.availability_zones_count) :
    cidrsubnet(var.vpc_cidr, 8, i)
  ]
}


variable "vpc_cidr" {
  type        = string
  description = "CIDR bloc for VPC - private IP range"
}

variable "availability_zones_count" {
  type        = number
  description = "Availability Zones count for HA"
}

variable "enable_nat_gateway" {
  type = bool
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"

  name = "${local.name_prefix}-vpc"
  cidr = var.vpc_cidr

  azs = local.azs

  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  public_subnet_tags = {
    Type = "public"
  }
  private_subnet_tags = {
    Type = "private"
  }

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true
}
