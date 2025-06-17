# modules/ecr/outputs.tf
output "repository_urls" {
  value = {
    for name, repo in aws_ecr_repository.repo : name => repo.repository_url
  }
}

output "repository_arns" {
  value = {
    for name, repo in aws_ecr_repository.repo : name => repo.arn
  }
}
