# modules/security/locals.tf
data "aws_default_tags" "current" {}

locals {
  name_prefix = "${data.aws_default_tags.current.tags["Owner"]}-${data.aws_default_tags.current.tags["Project"]}-${data.aws_default_tags.current.tags["Environment"]}"
}