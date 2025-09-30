# Infrastructure Update - Deployment Guide

## Changes Made

### 1. **Elastic IP for EC2 Backend (Static IP)**
   - Added Elastic IP resource to the EC2 instance
   - Backend APIs now have a static IP address that won't change on EC2 restart
   - Frontend will call backend APIs using this static IP (no DNS needed for backend)

### 2. **Route 53 Hosted Zone for Frontend Domain Only**
   - Created new Route 53 hosted zone for `sabeeltech-esg.dev`
   - Removed old Route 53 module that was handling backend API DNS
   - Route 53 is now only used for the frontend domain

### 3. **ACM Certificate for CloudFront**
   - Created ACM certificate in `us-east-1` (required by CloudFront)
   - Certificate covers `sabeeltech-esg.dev` and `*.sabeeltech-esg.dev`
   - DNS validation records are automatically created in Route 53
   - Certificate validation will happen automatically (may take 5-30 minutes)

### 4. **CloudFront with Custom Domain**
   - Updated CloudFront distribution to use custom domain `sabeeltech-esg.dev`
   - Configured CloudFront to use the ACM certificate
   - Created Route 53 A record pointing `sabeeltech-esg.dev` to CloudFront
   - Created Route 53 A record for `*.sabeeltech-esg.dev` (wildcard)

## Deployment Steps

### Step 1: Destroy Old Route 53 Resources

First, set `enable_route53 = false` in your terraform.tfvars to destroy the old Route 53 setup:

```bash
cd stacks/geo/development

# Edit terraform.tfvars and set:
# enable_route53 = false

# This will destroy the old Route 53 hosted zone and records
terraform destroy -target=module.shared_infrastructure
```

**OR** if you want to just remove the Route 53 resources without destroying everything:

```bash
# Just destroy the Route 53 module (this module no longer exists in the code)
terraform state rm 'module.shared_infrastructure.module.route53[0].aws_route53_zone.main'
terraform state rm 'module.shared_infrastructure.module.route53[0].aws_route53_record.backend_api'
terraform state rm 'module.shared_infrastructure.module.route53[0].aws_route53_record.frontend'
```

### Step 2: Configure Domain in terraform.tfvars

Edit `stacks/geo/development/terraform.tfvars`:

```hcl
# Domain configuration for frontend
domain_name    = "sabeeltech-esg.dev"
enable_route53 = true
```

### Step 3: Apply Infrastructure Changes

```bash
cd stacks/geo/development

# Initialize to download new providers
terraform init

# Apply changes
terraform apply
```

**Note:** The ACM certificate validation may take 5-30 minutes. Terraform will wait for validation to complete.

### Step 4: Configure Domain Nameservers

After the deployment completes, get the nameservers:

```bash
terraform output nameservers
```

Example output:
```
[
  "ns-1234.awsdns-56.org",
  "ns-789.awsdns-01.net",
  "ns-456.awsdns-23.com",
  "ns-012.awsdns-34.co.uk"
]
```

**Configure these nameservers in your domain registrar (OVH, GoDaddy, etc.)**

1. Login to your domain registrar
2. Find DNS/Nameserver settings for `sabeeltech-esg.dev`
3. Replace existing nameservers with the 4 AWS nameservers
4. Save changes

DNS propagation typically takes 15-60 minutes.

### Step 5: Get Backend Elastic IP

Get the static Elastic IP for backend APIs:

```bash
terraform output backend_elastic_ip
```

Example output:
```
52.47.123.45
```

**This IP will NOT change when you restart the EC2 instance.**

### Step 6: Update Frontend to Use Elastic IP

Update your React frontend configuration to call backend APIs using the Elastic IP:

```javascript
// src/config.js or .env
export const API_BASE_URL = 'http://52.47.123.45:5002';  // Replace with your Elastic IP

// OR use environment variable:
REACT_APP_API_URL=http://52.47.123.45:5002
```

**Note:** You're calling the backend directly by IP, not using DNS. This is cost-effective and the IP won't change.

### Step 7: Verify Setup

After DNS propagation (15-60 minutes):

```bash
# Check frontend domain
nslookup sabeeltech-esg.dev

# Test frontend access
curl -I https://sabeeltech-esg.dev
```

## Architecture Summary

### Frontend (React)
- **CloudFront URL:** `https://d1234abcd.cloudfront.net` (from CloudFront)
- **Custom Domain:** `https://sabeeltech-esg.dev` (after DNS propagation)
- **SSL Certificate:** Managed by AWS ACM (auto-renewed)

### Backend APIs
- **Static IP:** Use Elastic IP (e.g., `52.47.123.45`)
- **Ports:**
  - `5002` - Flask authentication service
  - `5000` - Flask reports service
  - `5001` - Flask additional service
  - `8000` - Django main application
- **No DNS:** Frontend calls backend APIs directly using Elastic IP

## Key Benefits

1. ✅ **Static Backend IP:** EC2 instance has a static Elastic IP (won't change on restart)
2. ✅ **Custom Frontend Domain:** Professional domain with SSL certificate
3. ✅ **Cost Optimized:** No Application Load Balancer needed
4. ✅ **Automatic Certificate Management:** ACM handles certificate renewal
5. ✅ **Simple Architecture:** Frontend uses custom domain, backend uses static IP

## Outputs Reference

After deployment, you can view all key information:

```bash
# All application URLs
terraform output application_urls

# Backend Elastic IP
terraform output backend_elastic_ip

# Frontend domain
terraform output frontend_domain

# Nameservers for domain registrar
terraform output nameservers

# ACM Certificate ARN
terraform output certificate_arn
```

## Troubleshooting

### Certificate Not Validating
- Wait 5-30 minutes for DNS propagation
- Check that nameservers are correctly configured in your domain registrar
- Verify DNS validation records in Route 53 console

### Frontend Domain Not Resolving
- Wait 15-60 minutes for DNS propagation after updating nameservers
- Clear local DNS cache: `sudo systemd-resolve --flush-caches` (Linux)
- Use `nslookup sabeeltech-esg.dev` to check DNS resolution

### Backend API Not Accessible
- Check EC2 security group allows traffic on ports 5002, 5000, 5001, 8000
- Verify Elastic IP is associated with EC2 instance
- Ensure backend services are running on EC2

## Cost Estimate

- **Elastic IP:** $0.00/month (free while attached to running instance)
- **Route 53 Hosted Zone:** $0.50/month
- **ACM Certificate:** $0.00/month (free)
- **DNS Queries:** ~$0.40/month for 1M queries
- **Total Additional Cost:** ~$1/month

## Next Steps

1. Apply terraform changes
2. Configure nameservers in domain registrar
3. Wait for DNS propagation (15-60 minutes)
4. Update React frontend to use Elastic IP for API calls
5. Test frontend at `https://sabeeltech-esg.dev`
6. Test backend APIs at `http://<ELASTIC_IP>:5002`
