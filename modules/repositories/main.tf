# modules/repositories/main.tf
resource "aws_codecommit_repository" "repos" {
  for_each = var.repositories

  repository_name = "${var.project}-${var.environment}-${each.value.name}"
  description     = each.value.description
  default_branch  = each.value.branch
  tags            = local.tags
}
