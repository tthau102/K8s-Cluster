# dev/providers.tf


provider "aws" {
  region = var.region
  default_tags {
    tags = merge(local.tags)
  }
}

locals {
  name_prefix = "${var.owner}-${var.project}-${var.environment}"

  tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    Manged_by   = "terraform"
  }
}



resource "aws_resourcegroups_group" "resourcegroup" {
  name        = "${local.name_prefix}-resourcesgroup"
  description = "All resource group for project"

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [
        {
          Key    = "Project"
          Values = [var.project]
        },
        {
          Key    = "Environment"
          Values = [var.environment]
        },
        {
          Key    = "Owner"
          Values = [var.owner]
        }
      ]
    })
  }

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-resourcesgroup"
  })
}
