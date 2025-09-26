output "frontend_bucket_name" {
  description = "Name of the S3 bucket hosting the React app"
  value       = aws_s3_bucket.frontend.bucket
}

output "frontend_bucket_arn" {
  description = "ARN of the S3 bucket hosting the React app"
  value       = aws_s3_bucket.frontend.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for the React app"
  value       = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name for the React app"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN for the React app"
  value       = aws_cloudfront_distribution.frontend.arn
}

output "website_url" {
  description = "URL of the React application"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}