# modules/repositories/outputs.tf
output "repository_urls" {
  value = {
    for k, v in aws_codecommit_repository.repos : k => {
      http = v.clone_url_http
      ssh  = v.clone_url_ssh
    }
  }
}

output "repository_names" {
  value = {
    for k, v in aws_codecommit_repository.repos : k => v.repository_name
  }
}

output "repository_arns" {
  value = {
    for k, v in aws_codecommit_repository.repos : k => v.arn
  }
}
