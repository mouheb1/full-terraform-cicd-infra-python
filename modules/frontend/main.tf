# S3 Bucket for React static website hosting - Ultra cost-optimized
resource "aws_s3_bucket" "frontend" {
  bucket        = "${var.namespace}-${var.environment}-frontend-${random_string.bucket_suffix.result}"
  force_destroy = true # Allow easy deletion for dev

  tags = merge(var.tags, {
    Name = "${var.namespace}-${var.environment}-frontend"
  })
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Static website configuration
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html" # React Router handling
  }
}

# Block direct public access - CloudFront will handle access
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning - disabled to save costs
resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  versioning_configuration {
    status = "Disabled" # No versioning to save costs
  }
}

# Server-side encryption with free AES256
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # Free encryption (not KMS)
    }
  }
}

# Lifecycle policy for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    id     = "frontend-cost-optimization"
    status = "Enabled"

    filter {
      prefix = ""
    }

    # Delete incomplete multipart uploads after 1 day
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }

    # Environment-aware expiration - only for non-current versions
    noncurrent_version_expiration {
      noncurrent_days = 7 # Keep old versions for 7 days only
    }
  }
}

# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "frontend_oac" {
  name                              = "${var.namespace}-${var.environment}-frontend-oac"
  description                       = "OAC for React app S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution for React app
resource "aws_cloudfront_distribution" "frontend" {
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend_oac.id
    origin_id                = "S3-${aws_s3_bucket.frontend.bucket}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.namespace} ${var.environment} React frontend"
  default_root_object = "index.html"

  # Default cache behavior optimized for React SPA
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.frontend.bucket}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    # Use forwarded_values for cost optimization
    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }

      headers = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]
    }

    # Cache settings optimized for React - shorter TTL for index.html
    min_ttl     = 0
    default_ttl = 300    # 5 minutes for HTML files
    max_ttl     = 86400  # 24 hours max
  }

  # Cache behavior for static assets (JS, CSS, images)
  ordered_cache_behavior {
    path_pattern     = "/static/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend.bucket}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400   # 1 day for static assets
    max_ttl                = 31536000 # 1 year for static assets
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Custom error responses for React Router
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  # Geographic restrictions
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
    Name = "${var.namespace}-${var.environment}-frontend-cloudfront"
  })
}

# S3 bucket policy for CloudFront OAC
data "aws_iam_policy_document" "frontend_cloudfront_oac" {
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
      "${aws_s3_bucket.frontend.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.frontend.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend_cloudfront_oac" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.frontend_cloudfront_oac.json
}