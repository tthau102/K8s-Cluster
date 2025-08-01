# shared-backend/1.4.outputs.tf



output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.tf_state_bucket.s3_bucket_id
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  value       = aws_dynamodb_table.tf_locks.name
}
