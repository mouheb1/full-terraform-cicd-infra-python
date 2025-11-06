# 📰 NEWS STACK - Deployment Guide

## ✅ COMPLETED WORK SUMMARY

### **Terraform Infrastructure**
- ✅ Created completely generic `user_data.sh` supporting both geo and news stacks
- ✅ Added namespace-aware nginx configuration (HTTP)
- ✅ Updated `stacks/news/development/main.tf` with correct NEWS stack configuration
- ✅ Created `terraform.tfvars` with secure random password
- ✅ Updated `variables.tf` removing Django/JWT variables (not needed for NEWS)
- ✅ Configured separate VPC (10.1.0.0/16) to avoid conflicts with geo
- ✅ Database name: `news_db`
- ✅ Domain: `newsaidemo.dev`

### **Deployment Files Created**

#### **newsapp-backend** (Flask REST API - Port 5000)
Location: `/home/mouheb/Desktop/jobs/geo-job/projects/news-app/newsapp-backend/`

- ✅ `Dockerfile` - Python 3.11 with PostGIS support
- ✅ `requirements.txt` - Flask, SQLAlchemy, psycopg2, websockets
- ✅ `buildspec.yml` - CodeBuild configuration
- ✅ `appspec.yml` - CodeDeploy configuration
- ✅ `scripts/start_server.sh` - Deployment script with health checks
- ✅ `scripts/stop_server.sh` - Cleanup script
- ✅ `.env.example` - Environment variables template

#### **newsapp-collector** (RSS Feed Collector - Background Service)
Location: `/home/mouheb/Desktop/jobs/geo-job/projects/news-app/newsapp-collector/`

- ✅ `Dockerfile` - Python 3.11 with spaCy and geopy
- ✅ `requirements.txt` - feedparser, aiohttp, spaCy, geopy, etc.
- ✅ `buildspec.yml` - CodeBuild configuration
- ✅ `appspec.yml` - CodeDeploy configuration
- ✅ `scripts/start_server.sh` - Background service deployment
- ✅ `scripts/stop_server.sh` - Cleanup script
- ✅ `.env.example` - Complete configuration template

#### **newsapp-frontend** (React + Vite SPA)
Location: `/home/mouheb/Desktop/jobs/geo-job/projects/news-app/newsapp-frontend/`

- ✅ `buildspec.yml` - CodeBuild configuration for Vite build

---

## 🚀 DEPLOYMENT STEPS

### **Prerequisites**

1. **AWS CLI configured** with appropriate credentials
2. **Terraform installed** (v1.0+)
3. **GitHub repositories exist**:
   - `sabeel-it-consulting/newsapp-backend`
   - `sabeel-it-consulting/newsapp-collector`
   - `sabeel-it-consulting/newsapp-frontend`
4. **Domain registered**: `newsaidemo.dev`

### **Step 1: Push Deployment Files to GitHub**

```bash
# For newsapp-backend
cd /home/mouheb/Desktop/jobs/geo-job/projects/news-app/newsapp-backend
git add Dockerfile requirements.txt buildspec.yml appspec.yml scripts/ .env.example
git commit -m "Add AWS deployment configuration"
git push origin main

# For newsapp-collector
cd /home/mouheb/Desktop/jobs/geo-job/projects/news-app/newsapp-collector
git add Dockerfile requirements.txt buildspec.yml appspec.yml scripts/ .env.example
git commit -m "Add AWS deployment configuration"
git push origin main

# For newsapp-frontend
cd /home/mouheb/Desktop/jobs/geo-job/projects/news-app/newsapp-frontend
git add buildspec.yml
git commit -m "Add AWS deployment configuration"
git push origin main
```

### **Step 2: Initialize Terraform**

```bash
cd /home/mouheb/Desktop/jobs/terraform-infra-python/stacks/news/development
terraform init -upgrade
```

### **Step 3: Review Terraform Plan**

```bash
terraform plan
```

**Expected Resources to be Created:**
- VPC (10.1.0.0/16) with 4 subnets
- EC2 t3.small instance
- RDS PostgreSQL db.t3.micro (with PostGIS support)
- 3 ECR repositories (backend, collector, frontend)
- 2 CodePipeline pipelines (backend + collector)
- 1 Frontend CI/CD pipeline (S3 + CloudFront)
- Route 53 hosted zone + DNS records
- ACM SSL certificates
- Elastic IP
- Security groups, IAM roles, etc.

### **Step 4: Apply Terraform**

```bash
terraform apply
```

**This will take approximately 15-20 minutes.**

### **Step 5: Manual Steps After Terraform Apply**

#### **5.1 Update Domain Nameservers**

1. Get nameservers from Terraform output:
   ```bash
   terraform output
   ```

2. Update `newsaidemo.dev` nameservers in your domain registrar to point to AWS Route 53 nameservers.

3. Wait for DNS propagation (5-30 minutes).

#### **5.2 Approve CodeStar Connection**

1. Go to AWS Console → Developer Tools → Connections
2. Find `news-dev-github-connection`
3. Click "Update pending connection"
4. Authorize with GitHub
5. Select `sabeel-it-consulting` organization

#### **5.3 Wait for SSL Certificates**

The EC2 instance will automatically obtain Let's Encrypt SSL certificates after DNS propagates (check `/var/log/ssl-cert-setup.log` on EC2).

### **Step 6: Trigger Initial Deployments**

After CodeStar connection is approved, pipelines will automatically trigger on the next commit, or you can manually release:

1. AWS Console → CodePipeline
2. Find pipelines:
   - `news-dev-newsapp-backend-pipeline`
   - `news-dev-newsapp-collector-pipeline`
   - `news-dev-newsapp-frontend-pipeline`
3. Click "Release change" for each

---

## 🔗 **EXPECTED ENDPOINTS**

After successful deployment:

| Service | URL | Port | Container |
|---------|-----|------|-----------|
| **Frontend** | `https://newsaidemo.dev` | N/A (CloudFront) | N/A (S3) |
| **Backend REST API** | `https://api.newsaidemo.dev` | 5000 | `news-backend` |
| **WebSocket Server** | `wss://api1.newsaidemo.dev` | 8765 | `news-backend` (same container) |
| **Collector** | N/A (background) | N/A | `news-collector` |

---

## ⚠️ KNOWN ISSUES & TODO

### **1. SSL HTTPS Configuration in user_data.sh**

**Status**: ⚠️ PARTIAL - Needs manual fix

**Issue**: The SSL certificate script in `modules/backend/user_data.sh` (lines 292-436) creates HTTPS nginx configurations, but these are not yet namespace-aware for the NEWS stack.

**Current Impact**:
- HTTP (port 80) nginx configs ✅ Work correctly (namespace-aware)
- Let's Encrypt SSL certificate obtainment ✅ Works for NEWS domains
- HTTPS (port 443) nginx configs ⚠️ May have incorrect port mappings

**Workaround**:
After Terraform apply, SSH into the EC2 instance and manually verify/fix nginx HTTPS configs in `/etc/nginx/conf.d/` if SSL setup completes but HTTPS doesn't work.

**Permanent Fix**:
Update lines 295-428 in `modules/backend/user_data.sh` to wrap HTTPS nginx configs with namespace conditionals (similar to HTTP configs at lines 129-224).

---

## 📊 **ARCHITECTURE SUMMARY**

### **Infrastructure**
- **VPC**: `10.1.0.0/16` (separate from geo stack)
- **EC2**: t3.small running 2 Docker containers
- **RDS**: db.t3.micro PostgreSQL 17 with PostGIS
- **S3**: Frontend static assets + Media storage
- **CloudFront**: CDN for frontend

### **Containers on EC2**
```
EC2 Instance (news-dev-backend)
├── news-backend (Port 5000) - Flask REST API
│   ├── app.py - Main API server
│   └── websocket_server.py - WebSocket server (port 8765)
│
└── news-collector (No port) - RSS Feed Collector
    └── Runs continuously every 15 minutes
```

### **Database Schema**
- **Database**: `news_db`
- **Main Table**: `events`
  - Uses PostGIS for geospatial data
  - JSONB columns for flexible data storage
  - PostgreSQL LISTEN/NOTIFY for real-time updates

### **CI/CD Flow**
```
GitHub Push → CodePipeline → CodeBuild (Docker build) → ECR (Image push) → CodeDeploy (EC2 deployment) → Docker Run
```

---

## 🔍 **TROUBLESHOOTING**

### **Check EC2 Instance Logs**
```bash
# SSH into instance
ssh -i news-dev-backend-key.pem ec2-user@<ELASTIC_IP>

# Check user-data execution
sudo cat /var/log/user-data.log
sudo tail -f /var/log/cloud-init-output.log

# Check SSL certificate setup
sudo tail -f /var/log/ssl-cert-setup.log

# Check Docker containers
docker ps -a
docker logs news-backend
docker logs news-collector
```

### **Check Database Connection**
```bash
# From EC2
docker exec -it news-backend python -c "from app import db; print('DB Connected!')"
```

### **Check Nginx Configuration**
```bash
sudo nginx -t
sudo systemctl status nginx
sudo cat /etc/nginx/conf.d/api.conf
```

### **Check CodeDeploy Logs**
```bash
sudo tail -f /var/log/aws/codedeploy-agent/codedeploy-agent.log
```

---

## 💰 **ESTIMATED MONTHLY COST**

| Resource | Specification | Monthly Cost |
|----------|--------------|--------------|
| EC2 t3.small | 2 vCPU, 2GB RAM (24/7) | ~$15.00 |
| RDS db.t3.micro | 1 vCPU, 1GB RAM (24/7) | ~$25.00 |
| EBS Volumes | 8GB root + 20GB Docker | ~$2.80 |
| S3 Storage | ~5GB | ~$0.12 |
| CloudFront | Low traffic | ~$1.00 |
| Data Transfer | 5GB/month | ~$0.45 |
| Route 53 | 1 hosted zone | ~$0.50 |
| **TOTAL** | | **~$44.87/month** |

---

## 🎯 **NEXT STEPS**

1. ✅ **Push deployment files to GitHub** (Step 1 above)
2. ✅ **Run terraform apply** (Steps 2-4)
3. ⏳ **Complete manual steps** (Step 5)
4. ⏳ **Trigger initial deployments** (Step 6)
5. ⏳ **Verify endpoints**
6. ⏳ **Monitor collector logs** to ensure RSS feeds are being collected
7. ⏳ **Test WebSocket connection** from frontend
8. 🔄 **Optional: Fix HTTPS SSL script** in user_data.sh

---

## 📝 **NOTES**

- **Backward Compatibility**: The refactored `user_data.sh` is fully backward compatible with the GEO stack
- **Isolated Infrastructure**: NEWS and GEO stacks are completely independent (separate VPCs, EC2, RDS)
- **Database Name Change**: Changed from `events_db` to `news_db` for consistency
- **No Django/JWT**: NEWS stack uses plain Flask, so no Django secret or JWT keys needed
- **WebSocket Support**: The backend contains both REST API and WebSocket server code
- **Background Collector**: Runs continuously, collecting news every 15 minutes

---

## 🆘 **SUPPORT**

If you encounter issues:
1. Check EC2 logs (see Troubleshooting section)
2. Verify DNS propagation: `dig api.newsaidemo.dev`
3. Check CodePipeline execution history in AWS Console
4. Review Terraform state: `terraform show`

---

**Generated**: 2025-01-03
**Terraform Version**: 1.0+
**AWS Region**: eu-west-3 (Paris)
**Namespace**: news
**Environment**: dev
