locals {
  backend_config = {
    s3_bucket_name      = module.tf_state_bucket.s3_bucket_id
    dynamodb_table_name = aws_dynamodb_table.tf_locks.name
    region              = var.region
  }
}

resource "local_file" "backend_dev" {
  content = templatefile("${path.module}/backend.hcl.tpl", merge(
    local.backend_config,
    { environment = "dev" }
  ))
  filename = "${path.module}/../dev/2.backend.tf"
}
