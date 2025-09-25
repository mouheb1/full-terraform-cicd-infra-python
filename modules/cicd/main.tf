# CodeStar Connection for GitHub integration (v2) - Only for primary backend
resource "aws_codestarconnections_connection" "github" {
  count         = var.backend_name == "backend" ? 1 : 0  # Create only for primary backend
  name          = "${var.namespace}-${var.environment}-github-connection"
  provider_type = "GitHub"

  tags = merge(var.tags, {
    Name = "${var.namespace}-${var.environment}-github-connection"
  })
}

# Data source to get existing CodeStar connection for secondary backends (only when ARN not provided)
data "aws_codestarconnections_connection" "existing" {
  count = var.backend_name != "backend" && var.codestar_connection_arn == "" ? 1 : 0
  name  = "${var.namespace}-${var.environment}-github-connection"
}

# Local value to determine which connection to use
locals {
  connection_arn = var.backend_name == "backend" ? aws_codestarconnections_connection.github[0].arn : (
    var.codestar_connection_arn != "" ? var.codestar_connection_arn : data.aws_codestarconnections_connection.existing[0].arn
  )
}

# ECR Repository for Docker images - Unique per backend
resource "aws_ecr_repository" "backend" {
  name                 = "${var.namespace}-${var.environment}-${var.backend_name}"
  image_tag_mutability = "MUTABLE"
  force_delete        = true
  
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.tags, {
    Name = "${var.namespace}-${var.environment}-${var.backend_name}-ecr"
  })
}

# ECR Lifecycle Policy - Aggressive cleanup to save storage costs
resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only last 3 images to save storage costs"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 3 # Keep only last 3 tagged images
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images after 1 day"
        selection = {
          tagStatus = "untagged"
          countType = "sinceImagePushed"
          countUnit = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# CodeDeploy application
resource "aws_codedeploy_app" "backend" {
  compute_platform = "Server"
  name             = "${var.namespace}-${var.environment}-${var.backend_name}"

  tags = merge(local.tags, {
    Name = "${var.namespace}-${var.environment}-${var.backend_name}-app"
  })
}

# IAM role for CodeDeploy - Unique per backend to avoid conflicts
resource "aws_iam_role" "codedeploy_role" {
  name = "${var.namespace}-${var.environment}-${var.backend_name}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.tags, {
    Name = "${var.namespace}-${var.environment}-${var.backend_name}-codedeploy-role"
  })
}

# Attach AWS managed policy for CodeDeploy
resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# CodeDeploy deployment group
resource "aws_codedeploy_deployment_group" "backend" {
  app_name              = aws_codedeploy_app.backend.name
  deployment_group_name = "${var.namespace}-${var.environment}-${var.backend_name}-deployment-group"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  ec2_tag_filter {
    key   = "Name"
    type  = "KEY_AND_VALUE"
    value = "${var.namespace}-${var.environment}-backend"  # All backends target the same EC2 instance
  }

  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  tags = merge(local.tags, {
    Name = "${var.namespace}-${var.environment}-${var.backend_name}-deployment-group"
  })
}

# S3 bucket for CodePipeline artifacts - Unique per backend to avoid conflicts
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "${var.namespace}-${var.environment}-${var.backend_name}-artifacts-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = merge(local.tags, {
    Name = "${var.namespace}-${var.environment}-${var.backend_name}-codepipeline-artifacts"
  })
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Removed S3 versioning to save storage costs
# resource "aws_s3_bucket_versioning" "codepipeline_artifacts" {
#   bucket = aws_s3_bucket.codepipeline_artifacts.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# Keep encryption (free with AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Lifecycle rule to delete old artifacts and save storage costs
resource "aws_s3_bucket_lifecycle_configuration" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id

  rule {
    id     = "delete_old_artifacts"
    status = "Enabled"

    filter {} # Empty filter to apply to all objects

    expiration {
      days = 7  # Delete artifacts after 7 days
    }

    noncurrent_version_expiration {
      noncurrent_days = 1  # Delete old versions after 1 day
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# IAM role for CodeBuild - Unique per backend
resource "aws_iam_role" "codebuild_role" {
  name = "${var.namespace}-${var.environment}-${var.backend_name}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.tags, {
    Name = "${var.namespace}-${var.environment}-${var.backend_name}-codebuild-role"
  })
}

# IAM policy for CodeBuild - Unique per backend
resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${var.namespace}-${var.environment}-${var.backend_name}-codebuild-policy"
  role = aws_iam_role.codebuild_role.id

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
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.codepipeline_artifacts.arn,
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      }
    ]
  })
}

# CodeBuild project
resource "aws_codebuild_project" "backend" {
  name          = "${var.namespace}-${var.environment}-${var.backend_name}-build"
  description   = "Build project for ${var.namespace} ${var.backend_name}"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"  # Smallest available type
    image                      = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode            = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.id
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.backend.name
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }

    environment_variable {
      name  = "NAMESPACE"
      value = var.namespace
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environment
    }
    environment_variable {
      name  = "BACKEND_NAME"
      value = var.backend_name
    }

    environment_variable {
      name  = "APPLICATION_PORT"
      value = tostring(var.application_port)
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"  # Root of application repo
  }

  tags = merge(var.tags, {
    Name = "${var.namespace}-${var.environment}-${var.backend_name}-build"
  })
}

# IAM role for CodePipeline - Unique per backend
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.namespace}-${var.environment}-${var.backend_name}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.namespace}-${var.environment}-${var.backend_name}-codepipeline-role"
  })
}

# IAM policy for CodePipeline - Unique per backend
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.namespace}-${var.environment}-${var.backend_name}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.codepipeline_artifacts.arn,
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = aws_codebuild_project.backend.arn
      },
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = local.connection_arn
      }
    ]
  })
}

# CodePipeline - Unique per backend
resource "aws_codepipeline" "backend" {
  name     = "${var.namespace}-${var.environment}-${var.backend_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = local.connection_arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo}"
        BranchName       = var.github_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.backend.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ApplicationName     = aws_codedeploy_app.backend.name
        DeploymentGroupName = aws_codedeploy_deployment_group.backend.deployment_group_name
      }
    }
  }

  tags = merge(local.tags, {
    Name = "${var.namespace}-${var.environment}-${var.backend_name}-pipeline"
  })
}