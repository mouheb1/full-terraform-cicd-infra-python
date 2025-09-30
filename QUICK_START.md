# Quick Start Guide

## 🚀 Deploy Infrastructure

```bash
cd stacks/geo/development

# 1. Edit terraform.tfvars
cat >> terraform.tfvars << EOF
domain_name    = "sabeeltech-esg.dev"
enable_route53 = true
EOF

# 2. Initialize and apply
terraform init -upgrade
terraform apply

# Wait for certificate validation (5-30 minutes)
```

## 📋 Get Important Values

```bash
# Get backend static IP (use this in frontend)
terraform output backend_elastic_ip

# Get nameservers (configure in domain registrar)
terraform output nameservers

# Get all URLs
terraform output application_urls
```

## 🌐 Configure Domain Registrar

1. Copy the 4 nameservers from `terraform output nameservers`
2. Login to your domain registrar (OVH, GoDaddy, etc.)
3. Find DNS/Nameserver settings for `sabeeltech-esg.dev`
4. Replace existing nameservers with the 4 AWS nameservers
5. Save and wait 15-60 minutes for DNS propagation

## 💻 Update React Frontend

```javascript
// In your React app config or .env file
const API_BASE_URL = 'http://YOUR_ELASTIC_IP:5002';

// Example:
const API_BASE_URL = 'http://52.47.123.45:5002';
```

Replace `YOUR_ELASTIC_IP` with the output from `terraform output backend_elastic_ip`

## ✅ Verify Deployment

```bash
# Check DNS resolution
nslookup sabeeltech-esg.dev

# Test frontend (after DNS propagation)
curl -I https://sabeeltech-esg.dev

# Test backend API
curl -I http://YOUR_ELASTIC_IP:5002
```

## 📊 Architecture

```
Frontend:
  https://sabeeltech-esg.dev (CloudFront + ACM Certificate)
  ↓
Backend APIs (Direct IP calls, no DNS):
  http://ELASTIC_IP:5002 - Auth service
  http://ELASTIC_IP:5000 - Reports service
  http://ELASTIC_IP:5001 - Additional service
  http://ELASTIC_IP:8000 - Django main app
```

## 💰 Cost

- Elastic IP: $0.00/month (free while attached)
- Route 53 Hosted Zone: $0.50/month
- ACM Certificate: $0.00/month (free)
- DNS Queries: ~$0.40/month
- **Total: ~$1/month**

## 📝 Key Points

✅ **Backend has static IP** - won't change on EC2 restart
✅ **Frontend has custom domain** - `https://sabeeltech-esg.dev`
✅ **SSL certificate managed by AWS** - auto-renewed
✅ **Frontend calls backend by IP** - no DNS needed

## 🔍 Troubleshooting

**Certificate not validating?**
- Wait 5-30 minutes after applying
- Ensure nameservers are configured in domain registrar

**Domain not resolving?**
- Wait 15-60 minutes after updating nameservers
- Check nameservers: `dig NS sabeeltech-esg.dev`

**Backend not accessible?**
- Check security groups allow traffic on ports 5002, 5000, 5001, 8000
- Verify services are running on EC2: `ssh ec2-user@ELASTIC_IP`

## 📚 Full Documentation

- `DEPLOYMENT_GUIDE.md` - Detailed deployment steps
- `CHANGES_SUMMARY.md` - Complete list of changes made
- `DNS_SETUP_GUIDE.md` - Original DNS setup guide (now outdated)
- `README.md` - Full infrastructure documentation

## 🆘 Getting Help

If something goes wrong:
1. Check `terraform plan` output
2. Review AWS Console (CloudFront, Route 53, EC2)
3. Check `DEPLOYMENT_GUIDE.md` troubleshooting section
4. Verify all security groups and IAM roles
