# S3 bucket for CodePipeline artifacts - Unique per frontend
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "${var.namespace}-${var.environment}-frontend-artifacts-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = merge(var.tags, {
    Name = "${var.namespace}-${var.environment}-frontend-codepipeline-artifacts"
  })
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

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

# IAM role for CodeBuild - Frontend build
resource "aws_iam_role" "codebuild_role" {
  name = "${var.namespace}-${var.environment}-frontend-codebuild-role"

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

  tags = merge(var.tags, {
    Name = "${var.namespace}-${var.environment}-frontend-codebuild-role"
  })
}

# IAM policy for CodeBuild - Frontend build with S3 and CloudFront permissions
resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${var.namespace}-${var.environment}-frontend-codebuild-policy"
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
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:PutObjectAcl"
        ]
        Resource = [
          var.frontend_bucket_arn,
          "${var.frontend_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        Resource = var.cloudfront_distribution_arn
      }
    ]
  })
}

# CodeBuild project for React build
resource "aws_codebuild_project" "frontend" {
  name          = "${var.namespace}-${var.environment}-frontend-build"
  description   = "Build project for ${var.namespace} React frontend"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"  # Smallest available type
    image                      = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.id
    }

    environment_variable {
      name  = "S3_BUCKET"
      value = var.frontend_bucket_name
    }

    environment_variable {
      name  = "CLOUDFRONT_DISTRIBUTION_ID"
      value = var.cloudfront_distribution_id
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
      name  = "REACT_APP_AUTH_BACKEND_URL"
      value = "http://${var.backend_public_dns}:5002"
    }

    environment_variable {
      name  = "REACT_APP_MAIN_BACKEND_URL"
      value = "http://${var.backend_public_dns}:8000"
    }

    environment_variable {
      name  = "REACT_APP_SECOND_BACKEND_URL"
      value = "http://${var.backend_public_dns}:5000"
    }

    environment_variable {
      name  = "REACT_APP_THIRD_BACKEND_URL"
      value = "http://${var.backend_public_dns}:5001"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"  # Root of React app repo
  }

  tags = merge(var.tags, {
    Name = "${var.namespace}-${var.environment}-frontend-build"
  })
}

# IAM role for CodePipeline - Frontend
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.namespace}-${var.environment}-frontend-codepipeline-role"

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
    Name = "${var.namespace}-${var.environment}-frontend-codepipeline-role"
  })
}

# IAM policy for CodePipeline - Frontend
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.namespace}-${var.environment}-frontend-codepipeline-policy"
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
        Resource = aws_codebuild_project.frontend.arn
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = var.codestar_connection_arn
      }
    ]
  })
}

# CodePipeline - Frontend
resource "aws_codepipeline" "frontend" {
  name     = "${var.namespace}-${var.environment}-frontend-pipeline"
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
        ConnectionArn    = var.codestar_connection_arn
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
        ProjectName = aws_codebuild_project.frontend.name
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.namespace}-${var.environment}-frontend-pipeline"
  })
}