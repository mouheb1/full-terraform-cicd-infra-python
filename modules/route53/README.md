# Route 53 DNS Module

This module creates and manages DNS records using AWS Route 53 for the GeoInvestInsights application.

## Features

- Creates a hosted zone for your domain
- Sets up `api.yourdomain.com` pointing to EC2 instance (for auth backend)
- Sets up `yourdomain.com` pointing to CloudFront distribution (for React frontend)
- Short TTL (60 seconds) for quick updates when EC2 IP changes
- Optional www redirect

## Configuration

### Required Variables

- `domain_name`: Your domain name (e.g., "mydomain.com")
- `ec2_public_ip`: EC2 instance public IP address
- `cloudfront_domain_name`: CloudFront distribution domain
- `cloudfront_hosted_zone_id`: CloudFront distribution hosted zone ID

### Setup Steps

1. **Deploy this module** with Terraform
2. **Get nameservers** from the output
3. **Configure OVH domain** to use Route 53 nameservers:
   - Login to OVH control panel
   - Go to your domain management
   - Replace OVH nameservers with the 4 nameservers from Terraform output

## Usage

The module automatically handles:
- `api.yourdomain.com` → EC2 instance (auth backend on port 5002)
- `yourdomain.com` → CloudFront distribution (React frontend)
- Automatic updates when EC2 IP changes (run `terraform apply`)

## IP Change Workflow

When EC2 IP changes:
1. Run `terraform apply`
2. Route 53 A record updates immediately
3. DNS propagation takes 1-2 minutes (TTL=60s)
4. Users might see brief connection issues during transition