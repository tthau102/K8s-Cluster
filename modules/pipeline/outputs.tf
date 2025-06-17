# modules/pipeline/outputs.tf
output "pipeline_arns" {
  value = {
    for k, v in aws_codepipeline.pipeline : k => v.arn
  }
}

output "codebuild_project_arns" {
  value = {
    for k, v in aws_codebuild_project.build : k => v.arn
  }
}

output "artifact_bucket" {
  value = aws_s3_bucket.artifacts.id
}
