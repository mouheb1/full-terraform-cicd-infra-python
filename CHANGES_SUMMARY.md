# Infrastructure Changes Summary

## Overview
This document summarizes the changes made to switch from DNS-based backend routing to static IP-based routing, while adding custom domain and SSL certificate support for the frontend.

## What Changed

### 1. Backend EC2 - Added Elastic IP (Static IP Address)
**Files Modified:**
- `modules/backend/main.tf`
- `modules/backend/outputs.tf`
- `modules/outputs.tf`
- `stacks/geo/development/outputs.tf`
- `stacks/geo/development/main.tf`

**Changes:**
- ✅ Added `aws_eip` resource to create a static Elastic IP for the EC2 instance
- ✅ Updated outputs to expose `backend_elastic_ip`
- ✅ Updated SSH commands to use Elastic IP instead of regular public IP
- ✅ Frontend CI/CD now uses Elastic IP for backend API calls

**Benefit:**
- Backend IP address is now **static** and won't change when EC2 instance is stopped/started
- No need for DNS for backend APIs - frontend calls backend directly by IP
- Cost-effective solution (Elastic IP is free while attached to running instance)

### 2. Removed Old Route 53 Module (Backend DNS)
**Files Modified:**
- `modules/main.tf`
- `modules/outputs.tf`

**Changes:**
- ❌ Removed `module.route53` that was creating DNS records for backend API
- ❌ Removed Route 53-related outputs (nameservers, hosted_zone_id, api_domain)
- ✅ Simplified infrastructure by eliminating unnecessary DNS for backend

**Why:**
- Backend APIs no longer need DNS - frontend calls them directly using Elastic IP
- Reduces complexity and potential points of failure
- Slightly reduces costs (though minimal)

### 3. Created New ACM Certificate Module
**Files Created:**
- `modules/acm-certificate/main.tf`
- `modules/acm-certificate/variables.tf`
- `modules/acm-certificate/outputs.tf`
- `modules/acm-certificate/versions.tf`

**What it Does:**
- ✅ Creates Route 53 hosted zone for `sabeeltech-esg.dev`
- ✅ Creates ACM certificate in `us-east-1` (required by CloudFront)
- ✅ Certificate covers both `sabeeltech-esg.dev` and `*.sabeeltech-esg.dev`
- ✅ Automatically creates DNS validation records in Route 53
- ✅ Waits for certificate validation to complete (may take 5-30 minutes)

**Benefit:**
- Enables HTTPS for the frontend with custom domain
- AWS manages certificate renewal automatically
- Professional appearance with custom domain

### 4. Updated Frontend Module for Custom Domain
**Files Modified:**
- `modules/frontend/main.tf`
- `modules/frontend/variables.tf`

**Changes:**
- ✅ Added variables: `domain_name`, `certificate_arn`, `hosted_zone_id`
- ✅ Updated CloudFront distribution to support custom domain aliases
- ✅ Configured CloudFront to use ACM certificate
- ✅ Added Route 53 A records pointing domain to CloudFront
- ✅ Added wildcard subdomain support (`*.sabeeltech-esg.dev`)

**Benefit:**
- Frontend accessible via `https://sabeeltech-esg.dev`
- SSL/TLS encryption provided by CloudFront
- Professional custom domain instead of CloudFront URL

### 5. Wired Everything Together in Stack
**Files Modified:**
- `stacks/geo/development/main.tf`
- `stacks/geo/development/providers.tf`
- `stacks/geo/development/outputs.tf`

**Changes:**
- ✅ Added `aws.us_east_1` provider for ACM certificate
- ✅ Added conditional `module.acm_certificate` call
- ✅ Updated `module.geo_frontend` to receive certificate and domain info
- ✅ Updated outputs to show Elastic IP, domain, nameservers, etc.

### 6. Documentation
**Files Created:**
- `DEPLOYMENT_GUIDE.md` - Step-by-step deployment instructions
- `CHANGES_SUMMARY.md` - This document

## Architecture Before vs After

### Before:
```
┌─────────────────────────────────────────────────┐
│ Route 53 Hosted Zone                            │
│  - api.mydomain.com → EC2 IP (changes on restart)│
│  - mydomain.com → CloudFront                    │
└─────────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────┐
│ EC2 Backend                                     │
│  - Public IP changes on restart                 │
│  - Port 5002, 5000, 5001, 8000                 │
└─────────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────┐
│ CloudFront                                      │
│  - Default CloudFront domain                    │
│  - Default SSL certificate                      │
└─────────────────────────────────────────────────┘
```

### After:
```
┌─────────────────────────────────────────────────┐
│ Route 53 Hosted Zone (sabeeltech-esg.dev)      │
│  - sabeeltech-esg.dev → CloudFront (A record)  │
│  - *.sabeeltech-esg.dev → CloudFront           │
│  - DNS validation records for ACM              │
└─────────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────┐
│ EC2 Backend with Elastic IP                     │
│  - Static IP: 52.47.123.45 (example)           │
│  - Port 5002, 5000, 5001, 8000                 │
│  - IP doesn't change on restart                │
└─────────────────────────────────────────────────┘
                 ↑
                 │ Direct API calls (no DNS)
                 │
┌─────────────────────────────────────────────────┐
│ CloudFront + ACM Certificate                    │
│  - Custom domain: sabeeltech-esg.dev           │
│  - SSL certificate (us-east-1)                 │
│  - Serves React frontend                       │
└─────────────────────────────────────────────────┘
```

## Configuration Requirements

### terraform.tfvars
```hcl
# Frontend custom domain
domain_name    = "sabeeltech-esg.dev"
enable_route53 = true

# Other existing variables...
```

### React Frontend Configuration
```javascript
// Use Elastic IP for backend API calls
const API_BASE_URL = 'http://52.47.123.45:5002'; // Replace with actual Elastic IP
```

## Deployment Process Summary

1. **Set `enable_route53 = true`** and **`domain_name = "sabeeltech-esg.dev"`** in terraform.tfvars
2. **Run `terraform apply`** to create new infrastructure
3. **Wait for certificate validation** (5-30 minutes)
4. **Configure nameservers** in domain registrar with Route 53 nameservers
5. **Wait for DNS propagation** (15-60 minutes)
6. **Update React frontend** to use Elastic IP for API calls
7. **Test frontend** at `https://sabeeltech-esg.dev`
8. **Test backend** at `http://<ELASTIC_IP>:5002`

## Key Outputs After Deployment

```bash
# Get static Elastic IP for backend
terraform output backend_elastic_ip

# Get nameservers for domain registrar
terraform output nameservers

# Get all application URLs
terraform output application_urls

# Get certificate ARN
terraform output certificate_arn

# Get frontend domain
terraform output frontend_domain
```

## Benefits of This Approach

1. ✅ **Static Backend IP:** EC2 IP won't change on restart
2. ✅ **Professional Frontend Domain:** `https://sabeeltech-esg.dev` with SSL
3. ✅ **Cost-Optimized:** No ALB needed, Elastic IP is free, Route 53 costs ~$1/month
4. ✅ **Simple Architecture:** Direct IP access for backend, custom domain for frontend
5. ✅ **Automatic SSL Management:** AWS ACM handles certificate renewal
6. ✅ **Wildcard Support:** `*.sabeeltech-esg.dev` covered by certificate

## Important Notes

- **Elastic IP is free** while attached to a running EC2 instance
- **ACM certificate is free** (AWS managed)
- **Route 53 costs** ~$1/month (hosted zone + queries)
- **Certificate validation** requires nameservers to be configured in domain registrar
- **DNS propagation** can take 15-60 minutes after nameserver changes
- **Frontend should call backend APIs** using the Elastic IP directly (no DNS)

## Troubleshooting

See `DEPLOYMENT_GUIDE.md` for detailed troubleshooting steps.

## Files Changed Summary

### Created:
- `modules/acm-certificate/main.tf`
- `modules/acm-certificate/variables.tf`
- `modules/acm-certificate/outputs.tf`
- `modules/acm-certificate/versions.tf`
- `DEPLOYMENT_GUIDE.md`
- `CHANGES_SUMMARY.md`

### Modified:
- `modules/backend/main.tf` - Added Elastic IP
- `modules/backend/outputs.tf` - Added Elastic IP outputs
- `modules/main.tf` - Removed Route 53 module
- `modules/outputs.tf` - Removed Route 53 outputs, added Elastic IP
- `modules/frontend/main.tf` - Added custom domain and certificate support
- `modules/frontend/variables.tf` - Added domain and certificate variables
- `stacks/geo/development/main.tf` - Added ACM module, updated frontend module
- `stacks/geo/development/providers.tf` - Added us-east-1 provider
- `stacks/geo/development/outputs.tf` - Updated outputs for new architecture

### No Changes:
- Database module
- Network module
- CI/CD modules
- S3 module

## Testing Checklist

After deployment:
- [ ] Elastic IP is allocated and attached to EC2
- [ ] Route 53 hosted zone is created for `sabeeltech-esg.dev`
- [ ] ACM certificate is issued and validated
- [ ] CloudFront distribution uses custom domain and certificate
- [ ] Route 53 A records point to CloudFront
- [ ] Nameservers configured in domain registrar
- [ ] DNS resolves `sabeeltech-esg.dev` to CloudFront
- [ ] Frontend accessible at `https://sabeeltech-esg.dev`
- [ ] Frontend can call backend APIs using Elastic IP
- [ ] Backend services running on ports 5002, 5000, 5001, 8000

## Rollback Plan

If you need to rollback:
1. Set `enable_route53 = false` in terraform.tfvars
2. Run `terraform apply`
3. This will destroy the ACM certificate and Route 53 resources
4. Elastic IP will remain (safe to keep or manually delete)
