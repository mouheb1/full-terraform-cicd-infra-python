# S3 Bucket - Ultra cost-optimized
resource "aws_s3_bucket" "storage" {
  bucket        = "${var.namespace}-${var.environment}-media-bucket"
  force_destroy = true # Allow easy deletion for dev

  tags = merge(var.tags, {
    Name = "${var.namespace}-${var.environment}-storage"
  })
}

# Block public access (security best practice)
resource "aws_s3_bucket_public_access_block" "storage" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning - disabled to save costs
resource "aws_s3_bucket_versioning" "storage" {
  bucket = aws_s3_bucket.storage.id
  versioning_configuration {
    status = "Disabled" # No versioning to save costs
  }
}

# Server-side encryption - disabled to save costs (enable in production)
resource "aws_s3_bucket_server_side_encryption_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # Free encryption (not KMS)
    }
  }
}

# Lifecycle policy - Environment-aware expiration
resource "aws_s3_bucket_lifecycle_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    id     = "cost-optimization"
    status = "Enabled"

    # Apply to all objects in the bucket
    filter {
      prefix = ""
    }

    # Delete incomplete multipart uploads after 1 day
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }

    # Environment-aware expiration
    dynamic "expiration" {
      for_each = var.environment == "prod" ? [] : [1]
      content {
        days = 30 # Keep files for 30 days in dev/test
      }
    }

    # No expiration in production (keep files forever)
    # Production files are valuable restaurant menu images
  }
}

# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${var.namespace}-${var.environment}-s3-oac"
  description                       = "OAC for S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.storage.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
    origin_id                = "S3-${aws_s3_bucket.storage.bucket}"
  }

  enabled = true
  comment = "${var.namespace} ${var.environment} media distribution"

  # Default cache behavior for restaurant images
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.storage.bucket}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    # Use forwarded_values instead of static cache policy IDs
    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    # Cache settings optimized for restaurant images - 2 days
    min_ttl     = 0
    default_ttl = 86400  # 1 day (24 hours)
    max_ttl     = 172800 # 2 days (48 hours)
  }

  # Geographic restrictions (optional - can help with costs)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Use cheapest price class for development
  price_class = var.environment == "prod" ? "PriceClass_All" : "PriceClass_100"

  # SSL certificate
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = merge(var.tags, {
    Name = "${var.namespace}-${var.environment}-cloudfront"
  })
}

# S3 bucket policy using proper IAM policy document
data "aws_iam_policy_document" "cloudfront_oac" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.storage.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront_oac" {
  bucket = aws_s3_bucket.storage.id
  policy = data.aws_iam_policy_document.cloudfront_oac.json
}

# VPC Endpoint for S3 - No data transfer charges for EC2 uploads!
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current.id}.s3"

  # Gateway endpoint (free) - not interface endpoint (costs money)
  vpc_endpoint_type = "Gateway"

  # Associate with private subnets route tables
  route_table_ids = data.aws_route_tables.private.ids

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.storage.arn,
          "${aws_s3_bucket.storage.arn}/*"
        ]
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.namespace}-${var.environment}-s3-endpoint"
  })
}

# Get route tables for private subnets
data "aws_route_tables" "private" {
  vpc_id = var.vpc_id

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

# IAM policy for EC2 to access S3
resource "aws_iam_policy" "s3_access" {
  name        = "${var.namespace}-${var.environment}-s3-access"
  description = "Allow EC2 to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.storage.arn,
          "${aws_s3_bucket.storage.arn}/*"
        ]
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.namespace}-${var.environment}-s3-policy"
  })
}
