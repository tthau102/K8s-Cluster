# modules/pipeline/main.tf

# Get current AWS account and region information
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#############################
# S3 Artifact Storage
#############################
resource "aws_s3_bucket" "artifacts" {
  bucket        = "${var.project}-${var.environment}-pipeline-artifacts"
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

#############################
# KMS Key cho Artifact Encryption
#############################
resource "aws_kms_key" "artifacts" {
  description             = "KMS key for pipeline artifacts"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CodePipeline to use the key"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.pipeline.arn
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.tags
}

resource "aws_kms_alias" "artifacts" {
  name          = "alias/${var.project}-${var.environment}-pipeline-artifacts"
  target_key_id = aws_kms_key.artifacts.key_id
}

#############################
# IAM Roles & Policies
#############################
resource "aws_iam_role" "codebuild" {
  name = "${var.project}-${var.environment}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "codebuild" {
  name = "${var.project}-${var.environment}-codebuild-policy"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
        ]
        Resource = [aws_kms_key.artifacts.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "pipeline" {
  name = "${var.project}-${var.environment}-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "pipeline" {
  name = "${var.project}-${var.environment}-pipeline-policy"
  role = aws_iam_role.pipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codecommit:CancelUploadArchive",
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:UploadArchive",
          "codecommit:GitPull"
        ]
        Resource = "arn:aws:codecommit:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:BatchGetBuildBatches",
          "codebuild:StartBuildBatch"
        ]
        Resource = [for project in aws_codebuild_project.build : project.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:*",
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "pipeline_kms" {
  name = "${var.project}-${var.environment}-pipeline-kms"
  role = aws_iam_role.pipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
        ]
        Resource = [aws_kms_key.artifacts.arn]
      }
    ]
  })
}

#############################
# CloudWatch Events Configuration
#############################
resource "aws_iam_role" "events" {
  name = "${var.project}-${var.environment}-events-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "events_trigger_pipeline" {
  name = "${var.project}-${var.environment}-events-policy"
  role = aws_iam_role.events.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "codepipeline:StartPipelineExecution"
      ]
      Resource = [for pipeline in aws_codepipeline.pipeline : pipeline.arn]
    }]
  })
}

resource "aws_cloudwatch_event_rule" "repository_changes" {
  for_each = var.repository_configs

  name        = "${var.project}-${var.environment}-${each.key}-events"
  description = "Capture CodeCommit repository changes"

  event_pattern = jsonencode({
    source      = ["aws.codecommit"]
    detail-type = ["CodeCommit Repository State Change"]
    resources   = ["arn:aws:codecommit:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${each.value.repository_name}"]
    detail = {
      event         = ["referenceUpdated"]
      referenceType = ["branch"]
      referenceName = [each.value.branch_name]
    }
  })

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "trigger_pipeline" {
  for_each = var.repository_configs

  rule      = aws_cloudwatch_event_rule.repository_changes[each.key].name
  target_id = "CodePipeline"
  arn       = aws_codepipeline.pipeline[each.key].arn
  role_arn  = aws_iam_role.events.arn
}

#############################
# CodeBuild Projects
#############################
resource "aws_codebuild_project" "build" {
  for_each = var.repository_configs

  name          = "${var.project}-${var.environment}-${each.key}-build"
  description   = "Builds ${each.key} application for ${var.environment}"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = "30"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    dynamic "environment_variable" {
      for_each = each.key == "frontend" ? [1] : []
      content {
        name  = "REACT_APP_API_URL"
        value = "/api"
        type  = "PLAINTEXT"
      }
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.name
    }

    environment_variable {
      name  = "ECR_REPOSITORY_URL"
      value = each.value.ecr_repo_url
    }

    environment_variable {
      name  = "CONTAINER_NAME"
      value = each.value.container_name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = each.value.build_specfile
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/codebuild/${var.project}-${var.environment}-${each.key}"
      stream_name = "build-logs"
      status      = "ENABLED"
    }
  }

  tags = local.tags
}

#############################
# CodePipeline
#############################
resource "aws_codepipeline" "pipeline" {
  for_each = var.repository_configs

  name     = "${var.project}-${var.environment}-${each.key}-pipeline"
  role_arn = aws_iam_role.pipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"

    encryption_key {
      id   = aws_kms_key.artifacts.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName       = each.value.repository_name
        BranchName           = each.value.branch_name
        PollForSourceChanges = false
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.build[each.key].name
      }

      output_artifacts = ["build_output"]
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName = var.ecs_cluster_name
        ServiceName = each.value.service_name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}

#############################
# Enhanced Monitoring
#############################
resource "aws_cloudwatch_log_group" "pipeline" {
  for_each = var.repository_configs

  name              = "/aws/codepipeline/${var.project}-${var.environment}-${each.key}"
  retention_in_days = 30

  tags = local.tags
}
