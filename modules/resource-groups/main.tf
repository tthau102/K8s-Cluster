# modules/resource-groups/main.tf
resource "aws_resourcegroups_group" "app" {
  name        = "${var.project}-${var.environment}-group"
  description = "Resource group for ${var.project} ${var.environment}"

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
        }
      ]
    })
  }

  tags = local.tags
}

resource "aws_resourcegroups_group" "compute" {
  name        = "${var.project}-${var.environment}-compute"
  description = "Compute resources"

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = [
        "AWS::ECS::Cluster",
        "AWS::ECS::Service",
        "AWS::ECS::TaskDefinition",
        "AWS::EC2::Instance"
      ]
      TagFilters = [
        {
          Key    = "Project"
          Values = [var.project]
        },
        {
          Key    = "Environment"
          Values = [var.environment]
        }
      ]
    })
  }

  tags = local.tags
}

resource "aws_resourcegroups_group" "network" {
  name        = "${var.project}-${var.environment}-network"
  description = "Network resources"

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = [
        "AWS::EC2::VPC",
        "AWS::EC2::Subnet",
        "AWS::EC2::SecurityGroup",
        "AWS::ElasticLoadBalancingV2::LoadBalancer"
      ]
      TagFilters = [
        {
          Key    = "Project"
          Values = [var.project]
        },
        {
          Key    = "Environment"
          Values = [var.environment]
        }
      ]
    })
  }

  tags = local.tags
}
