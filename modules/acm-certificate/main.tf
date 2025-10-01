# Route 53 Hosted Zone for the domain
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = merge(var.tags, {
    Name = "${var.namespace}-${var.environment}-hosted-zone"
  })
}

# ACM Certificate in us-east-1 for CloudFront
resource "aws_acm_certificate" "cloudfront" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  tags = merge(var.tags, {
    Name = "${var.namespace}-${var.environment}-cloudfront-cert"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Create DNS validation records in Route 53
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

# Wait for certificate validation to complete
resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Route 53 A record for API subdomain (points to EC2 Elastic IP - port 5002 Auth)
resource "aws_route53_record" "api" {
  count   = var.backend_elastic_ip != "" ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [var.backend_elastic_ip]
}

# Route 53 A record for API1 subdomain (points to EC2 Elastic IP - port 8000 Django)
resource "aws_route53_record" "api1" {
  count   = var.backend_elastic_ip != "" ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "api1.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [var.backend_elastic_ip]
}

# Route 53 A record for API2 subdomain (points to EC2 Elastic IP - port 5000 Reports)
resource "aws_route53_record" "api2" {
  count   = var.backend_elastic_ip != "" ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "api2.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [var.backend_elastic_ip]
}

# Route 53 A record for API3 subdomain (points to EC2 Elastic IP - port 5001 Service)
resource "aws_route53_record" "api3" {
  count   = var.backend_elastic_ip != "" ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "api3.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [var.backend_elastic_ip]
}
