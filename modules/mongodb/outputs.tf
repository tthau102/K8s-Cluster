# modules/mongodb/outputs.tf
output "mongodb_instance_id" {
  value = aws_instance.mongodb.id
}

output "mongodb_private_ip" {
  value = aws_instance.mongodb.private_ip
}

# Thêm vào modules/mongodb/outputs.tf
output "connection_string_arn" {
  description = "ARN of MongoDB connection string in Parameter Store"
  value       = aws_ssm_parameter.mongodb_connection_string.arn
}
