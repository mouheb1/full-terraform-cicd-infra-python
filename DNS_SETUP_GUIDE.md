# DNS Setup Guide with Route 53

This guide explains how to configure your OVH domain to work with the GeoInvestInsights infrastructure, automatically routing traffic to the correct services.

## Architecture Overview

The DNS setup creates the following domain routing:
- **`api.mydomain.com`** → EC2 instance (auth backend on port 5002)
- **`mydomain.com`** → CloudFront distribution (React frontend)

## Prerequisites

- OVH domain registered and accessible
- Terraform infrastructure deployed
- Access to OVH domain control panel

## Step 1: Enable DNS in Terraform

### 1.1 Configure terraform.tfvars

Add these variables to your `terraform.tfvars` file:

```hcl
# DNS Configuration
domain_name    = "mydomain.com"  # Replace with your actual domain
enable_route53 = true
```

### 1.2 Deploy with Terraform

```bash
cd stacks/geo/development
terraform apply
```

### 1.3 Get Nameservers

After deployment, get the nameservers:

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

## Step 2: Configure OVH Domain

### 2.1 Access OVH Control Panel

1. Login to your OVH control panel
2. Navigate to "Web Cloud" → "Domain names"
3. Select your domain

### 2.2 Update DNS Servers

1. Go to "DNS servers" tab
2. Click "Modify DNS servers"
3. Replace the default OVH nameservers with the 4 AWS nameservers from the Terraform output
4. Save the changes

### 2.3 Wait for Propagation

DNS propagation typically takes:
- **15-60 minutes**: Most changes are visible
- **Up to 24 hours**: Full global propagation

## Step 3: Verify Setup

### 3.1 Check DNS Resolution

```bash
# Check API domain
nslookup api.mydomain.com

# Check frontend domain
nslookup mydomain.com
```

### 3.2 Test Application Access

```bash
# Test React frontend
curl -I https://mydomain.com

# Test auth backend (should return 404 for root, which is normal)
curl -I https://api.mydomain.com
```

## Step 4: Update Application Configuration

### 4.1 React Frontend Configuration

Update your React app to use the custom domain:

```javascript
// src/config.js
export const API_BASE_URL = 'https://api.mydomain.com';

// Example API call
fetch(`${API_BASE_URL}/auth/login`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ username, password })
});
```

### 4.2 Backend Configuration

The auth backend (port 5002) should be configured to:
- Accept requests from `api.mydomain.com`
- Set appropriate CORS headers for `https://mydomain.com`

## Step 5: Handle EC2 IP Changes

When you stop/start the EC2 instance, the IP changes. Here's how to update:

### 5.1 Update DNS Records

```bash
cd stacks/geo/development
terraform apply
```

### 5.2 Propagation Timeline

- **Route 53 Update**: Immediate (seconds)
- **DNS Cache Expiry**: 60 seconds (TTL setting)
- **User Impact**: 1-2 minutes of potential connectivity issues

### 5.3 Minimize Impact

Implement retry logic in your React app:

```javascript
async function apiCall(url, options = {}, retries = 3) {
  try {
    const response = await fetch(`https://api.mydomain.com${url}`, options);
    if (!response.ok) throw new Error('API error');
    return response;
  } catch (error) {
    if (retries > 0) {
      console.log(`Retrying API call... ${retries} attempts left`);
      await new Promise(resolve => setTimeout(resolve, 1000));
      return apiCall(url, options, retries - 1);
    }
    throw error;
  }
}
```

## Troubleshooting

### DNS Not Resolving

1. **Check nameservers**: Verify OVH is using AWS nameservers
2. **Wait longer**: DNS propagation can take up to 24 hours
3. **Clear DNS cache**: `sudo systemctl flush-dns` (Linux) or `ipconfig /flushdns` (Windows)

### SSL Certificate Issues

CloudFront automatically provides SSL certificates for the frontend. For the API domain, you may need to:
1. Use Let's Encrypt or AWS Certificate Manager
2. Configure SSL termination on the EC2 instance
3. Or use a reverse proxy like nginx

### Connection Refused Errors

1. **Check security groups**: Ensure port 5002 is open
2. **Verify auth service**: Confirm the auth backend is running on port 5002
3. **Check firewall**: Ensure EC2 instance allows incoming connections

## Cost Estimate

- **Route 53 Hosted Zone**: $0.50/month
- **DNS Queries**: ~$0.40/month for 1M queries
- **Total**: ~$1/month

## Summary

This setup provides:
- ✅ Professional domain names instead of IP addresses
- ✅ Automatic DNS updates when EC2 IP changes
- ✅ SSL termination via CloudFront for frontend
- ✅ Cost-effective solution (~$1/month)
- ✅ Production-ready with proper retry logic

The brief connectivity issues during IP changes (1-2 minutes) are acceptable for the massive cost savings compared to using an Application Load Balancer.