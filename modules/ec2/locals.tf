# modules/ec2/locals.tf

# Get current provider default tags
data "aws_default_tags" "current" {}

locals {
  # Name prefix from provider tags (auto-inherited)
  name_prefix = "${data.aws_default_tags.current.tags["Owner"]}-${data.aws_default_tags.current.tags["Project"]}-${data.aws_default_tags.current.tags["Environment"]}"
}