# Route 53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = merge(var.tags, {
    Name = "${var.namespace}-${var.environment}-hosted-zone"
  })
}

# Backend API record (pointing to EC2 instance for auth container)
resource "aws_route53_record" "backend_api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  ttl     = 60  # Short TTL for quick updates when EC2 IP changes
  records = [var.ec2_public_ip]
}

# Frontend record (pointing to CloudFront distribution)
resource "aws_route53_record" "frontend" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# WWW redirect (optional - redirects www.domain.com to domain.com)
resource "aws_route53_record" "frontend_www" {
  count   = var.create_www_redirect ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}