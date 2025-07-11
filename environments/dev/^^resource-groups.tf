# environments/dev/resource-groups.tf
locals {
  name_prefix = "${var.owner}-${var.project}-${var.environment}"
}

resource "aws_resourcegroups_group" "dev_resources" {
  name        = "${local.name_prefix}-resourcesgroup"
  description = "All resources for k8s-pj dev environment"

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

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-resourcesgroup"
  })
}
