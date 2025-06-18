# modules/vpc/locals.tf
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Calculate AZs to use
  azs = slice(data.aws_availability_zones.available.names, 0, var.availability_zones_count)

  # Subnet calculations
  public_subnets  = [for i in range(var.availability_zones_count) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnets = [for i in range(var.availability_zones_count) : cidrsubnet(var.vpc_cidr, 8, i + 10)]

  # Name prefix from provider tags (auto-inherited)
  name_prefix = "${data.aws_default_tags.current.tags["Owner"]}-${data.aws_default_tags.current.tags["Project"]}-${data.aws_default_tags.current.tags["Environment"]}"
}

# Get current provider default tags
data "aws_default_tags" "current" {}
