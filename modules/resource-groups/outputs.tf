# modules/resource-groups/outputs.tf
output "group_arns" {
  value = {
    app     = aws_resourcegroups_group.app.arn
    compute = aws_resourcegroups_group.compute.arn
    network = aws_resourcegroups_group.network.arn
  }
}
