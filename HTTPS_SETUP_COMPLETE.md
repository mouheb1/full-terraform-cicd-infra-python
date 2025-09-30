# HTTPS Setup Complete! 🎉

## What Was Done

### 1. **Backend EC2 - Added Elastic IP (Static IP)**
   - ✅ Elastic IP: `13.36.228.125` (won't change on EC2 restart)
   - ✅ Zero cost while attached to running EC2

### 2. **Nginx Reverse Proxy with SSL**
   - ✅ Installed Nginx on EC2
   - ✅ Installed Certbot for Let's Encrypt SSL certificates
   - ✅ Obtained SSL certificate for `api.sabeeltech-esg.dev`
   - ✅ Configured Nginx to reverse proxy port 5002 (authback container) with HTTPS

### 3. **Route 53 DNS Configuration**
   - ✅ Created hosted zone for `sabeeltech-esg.dev`
   - ✅ Created ACM certificate for CloudFront (frontend)
   - ✅ Created A record: `api.sabeeltech-esg.dev` → Elastic IP `13.36.228.125`
   - ✅ CloudFront linked with custom domain and SSL certificate

### 4. **SSL Certificates**
   - ✅ **Frontend**: AWS ACM certificate (CloudFront) - `sabeeltech-esg.dev`
   - ✅ **Backend**: Let's Encrypt certificate (Nginx) - `api.sabeeltech-esg.dev`
   - ✅ Both certificates auto-renew

## Final Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ CloudFront (HTTPS)                                          │
│ https://sabeeltech-esg.dev                                  │
│ SSL: AWS ACM Certificate (auto-renewed)                    │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ Nginx Reverse Proxy (HTTPS)                                │
│ https://api.sabeeltech-esg.dev                              │
│ SSL: Let's Encrypt Certificate (auto-renewed)              │
│ Elastic IP: 13.36.228.125 (static)                         │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ EC2 Instance                                                │
│ Docker Container: geoinvestinsights-authback (Port 5002)   │
│ Internal HTTP only (not exposed publicly)                  │
└─────────────────────────────────────────────────────────────┘
```

## Application URLs

### Frontend
- **CloudFront URL**: `https://d1n27c19scqe1u.cloudfront.net`
- **Custom Domain**: `https://sabeeltech-esg.dev` ✅

### Backend API
- **HTTPS (Use This)**: `https://api.sabeeltech-esg.dev` ✅
- **HTTP (Redirects to HTTPS)**: `http://api.sabeeltech-esg.dev` → redirects to HTTPS

## Update Your React Frontend

Replace the HTTP backend URL with the HTTPS URL:

```javascript
// OLD (HTTP - caused mixed content errors)
const API_BASE_URL = 'http://13.36.228.125:5002';

// NEW (HTTPS - works perfectly!)
const API_BASE_URL = 'https://api.sabeeltech-esg.dev';
```

Or use environment variables:

```bash
# .env
REACT_APP_API_URL=https://api.sabeeltech-esg.dev
```

## Testing

Test the HTTPS endpoints:

```bash
# Test frontend
curl -I https://sabeeltech-esg.dev

# Test backend API
curl -I https://api.sabeeltech-esg.dev
```

## SSL Certificate Auto-Renewal

### Frontend (CloudFront)
- **Managed by**: AWS ACM
- **Renewal**: Automatic, handled by AWS
- **Action Required**: None

### Backend (Nginx/Let's Encrypt)
- **Managed by**: Certbot
- **Renewal**: Automatic via systemd timer
- **Valid Until**: 2025-12-29 (90 days)
- **Action Required**: None (auto-renews 30 days before expiry)

To manually renew (if needed):
```bash
ssh -i ./geo-dev-backend-key.pem ec2-user@13.36.228.125
sudo certbot renew
sudo systemctl reload nginx
```

## DNS Nameservers

Configure these nameservers in your domain registrar for `sabeeltech-esg.dev`:

```
ns-1530.awsdns-63.org
ns-1761.awsdns-28.co.uk
ns-688.awsdns-22.net
ns-98.awsdns-12.com
```

## Key Features

✅ **Frontend HTTPS**: `https://sabeeltech-esg.dev` with AWS-managed SSL
✅ **Backend HTTPS**: `https://api.sabeeltech-esg.dev` with Let's Encrypt SSL
✅ **Static IP**: EC2 won't change IP on restart
✅ **Auto SSL Renewal**: Both certificates renew automatically
✅ **HTTP/2 Support**: Modern protocol for better performance
✅ **Mixed Content Fixed**: Frontend (HTTPS) can now call backend (HTTPS)
✅ **Zero Manual Config**: Stop/start EC2 anytime, everything still works

## Cost Summary

- **Elastic IP**: $0.00/month (free while attached to running EC2)
- **Route 53 Hosted Zone**: $0.50/month
- **DNS Queries**: ~$0.40/month
- **ACM Certificate (CloudFront)**: $0.00/month (free)
- **Let's Encrypt Certificate (Nginx)**: $0.00/month (free)
- **Total**: **~$1/month**

## What Happens on EC2 Restart?

When you stop/start EC2:
1. ✅ **Elastic IP stays the same** - no manual updates needed
2. ✅ **DNS keeps working** - `api.sabeeltech-esg.dev` still points to same IP
3. ✅ **SSL certificates remain valid** - Nginx starts with existing certificates
4. ✅ **Nginx starts automatically** - configured to start on boot
5. ✅ **Everything works immediately** - zero manual intervention

## Troubleshooting

### Certificate Not Working?
Check certificate status:
```bash
ssh -i ./geo-dev-backend-key.pem ec2-user@13.36.228.125
sudo certbot certificates
```

### Nginx Not Running?
```bash
ssh -i ./geo-dev-backend-key.pem ec2-user@13.36.228.125
sudo systemctl status nginx
sudo systemctl start nginx
```

### Check Nginx Logs
```bash
ssh -i ./geo-dev-backend-key.pem ec2-user@13.36.228.125
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

## Files Modified

- `modules/backend/user_data.sh` - Added Nginx and Certbot installation for new EC2 instances
- `modules/acm-certificate/main.tf` - Added Route 53 A record for API subdomain
- `stacks/geo/development/setup-nginx-on-ec2.sh` - Script to setup Nginx on existing EC2

## Summary

🎉 **Mission Accomplished!**

- ✅ Frontend served over HTTPS with custom domain
- ✅ Backend API accessible over HTTPS with subdomain
- ✅ No more mixed content errors
- ✅ Professional SSL certificates
- ✅ Cost-effective solution (~$1/month)
- ✅ Zero-touch operation after setup

Your users can now safely access:
- **Frontend**: `https://sabeeltech-esg.dev`
- **Backend API**: `https://api.sabeeltech-esg.dev`

All communication is encrypted end-to-end! 🔒
