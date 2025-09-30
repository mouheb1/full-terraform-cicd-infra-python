output "hosted_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "nameservers" {
  description = "Route 53 nameservers to configure in OVH"
  value       = aws_route53_zone.main.name_servers
}

output "domain_name" {
  description = "The domain name"
  value       = var.domain_name
}

output "api_domain" {
  description = "API subdomain (for backend auth service)"
  value       = "api.${var.domain_name}"
}

output "frontend_domain" {
  description = "Frontend domain"
  value       = var.domain_name
}

output "hosted_zone_arn" {
  description = "Route 53 hosted zone ARN"
  value       = aws_route53_zone.main.arn
}