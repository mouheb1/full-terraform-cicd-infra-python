# GeoInvestInsights Terraform Infrastructure

Complete AWS infrastructure for a multi-tier full-stack application with React frontend, multiple Python backends (Django + Flask), PostgreSQL database, and automated CI/CD pipelines.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Architecture Overview](#architecture-overview)
3. [Prerequisites](#prerequisites)
4. [Initial Setup](#initial-setup)
5. [Module Reference](#module-reference)
6. [Deployment Guide](#deployment-guide)
7. [Post-Deployment Configuration](#post-deployment-configuration)
8. [Destroy and Recreate](#destroy-and-recreate)
9. [Troubleshooting](#troubleshooting)
10. [Cost Breakdown](#cost-breakdown)

---

## Quick Start

```bash
# 1. Navigate to the stack directory
cd stacks/geo/development

# 2. Create terraform.tfvars with your configuration
cat > terraform.tfvars << EOF
# Database credentials
db_username      = "postgres"
db_password      = "your-secure-password"

# Django secret key
django_secret_key = "your-django-secret-key"

# JWT secret for Flask authentication
jwt_secret_key    = "your-jwt-secret"

# Custom domain configuration
domain_name    = "sabeeltech-esg.dev"
enable_route53 = true
EOF

# 3. Initialize and deploy
terraform init -upgrade
terraform apply

# 4. Get deployment outputs
terraform output application_urls
terraform output nameservers
terraform output backend_elastic_ip
```

---

## Architecture Overview

### Infrastructure Components

```
┌──────────────────────────────────────────────────────────────┐
│                      AWS Cloud                                │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Route 53 (DNS)                                         │  │
│  │ - sabeeltech-esg.dev → CloudFront                     │  │
│  │ - api.sabeeltech-esg.dev → EC2 Elastic IP            │  │
│  │ - api1.sabeeltech-esg.dev → EC2 Elastic IP           │  │
│  │ - api2.sabeeltech-esg.dev → EC2 Elastic IP           │  │
│  │ - api3.sabeeltech-esg.dev → EC2 Elastic IP           │  │
│  └────────────────────────────────────────────────────────┘  │
│                        ↓                ↓                     │
│  ┌─────────────────────────┐  ┌────────────────────────────┐│
│  │ CloudFront (HTTPS)      │  │ Nginx Reverse Proxy        ││
│  │ + ACM Certificate       │  │ + Let's Encrypt SSL        ││
│  │ (Frontend)              │  │ (All 4 API Endpoints)      ││
│  └─────────────────────────┘  └────────────────────────────┘│
│              ↓                   ↓      ↓      ↓      ↓      │
│  ┌─────────────────────────┐  api   api1   api2   api3     │
│  │ S3 Bucket               │  :5002  :8000  :5000  :5001    │
│  │ (React Static Files)    │    ↓      ↓      ↓      ↓      │
│  │                         │  ┌────────────────────────────┐│
│  └─────────────────────────┘  │ EC2 t3.small               ││
│                                │ Elastic IP: Static         ││
│  ┌─────────────────────────┐  │ ┌────────────────────────┐ ││
│  │ RDS PostgreSQL          │◄─┤ │ Docker Containers:     │ ││
│  │ (Shared Database)       │  │ │ - Flask Auth (5002)    │ ││
│  └─────────────────────────┘  │ │ - Django (8000)        │ ││
│                                │ │ - Flask Reports (5000) │ ││
│                                │ │ - Flask Service (5001) │ ││
│                                │ └────────────────────────┘ ││
│                                └────────────────────────────┘│
│  ┌──────────────────────────────────────────────────────────┐│
│  │ CI/CD Pipeline (per service)                             ││
│  │ GitHub → CodePipeline → CodeBuild → ECR → CodeDeploy    ││
│  └──────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────┘
```

### Application URLs

**Frontend:**
- CloudFront: `https://d1234abcd.cloudfront.net`
- Custom Domain: `https://sabeeltech-esg.dev`

**Backend APIs:**
- Auth (HTTPS): `https://api.sabeeltech-esg.dev` (Port 5002)
- Django (HTTPS): `https://api1.sabeeltech-esg.dev` (Port 8000)
- Reports (HTTPS): `https://api2.sabeeltech-esg.dev` (Port 5000)
- Service (HTTPS): `https://api3.sabeeltech-esg.dev` (Port 5001)

---

## Prerequisites

### Required Tools
- **Terraform** >= 1.0
- **AWS CLI** configured with appropriate credentials
- **Git** for repository management
- **SSH client** for EC2 access

### AWS Account Requirements
- Valid AWS account with admin/developer access
- AWS CLI configured with profile named `geo`
- GitHub account with repositories for each service

### Domain Registration
- Domain registered (e.g., via OVH, GoDaddy)
- Access to domain registrar's DNS settings

---

## Initial Setup

### Step 1: Clone Repository

```bash
git clone <your-repo-url>
cd terraform-infra-python/stacks/geo/development
```

### Step 2: Configure AWS Profile

```bash
# Configure AWS CLI with 'geo' profile
aws configure --profile geo
```

Enter your AWS credentials when prompted.

### Step 3: Create terraform.tfvars

Create `stacks/geo/development/terraform.tfvars`:

```hcl
# Database Configuration
db_username      = "postgres"
db_password      = "YourSecurePassword123!"

# Django Configuration
django_secret_key = "your-random-50-character-django-secret-key"

# Flask Auth Configuration
jwt_secret_key    = "your-random-jwt-secret-key"

# Custom Domain (Optional - set enable_route53 = false to disable)
domain_name    = "sabeeltech-esg.dev"
enable_route53 = true
```

**Generate Secure Keys:**
```bash
# Django secret key
python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'

# JWT secret
openssl rand -base64 32
```

### Step 4: Initialize Terraform

```bash
terraform init -upgrade
```

---

## Module Reference

### 1. **Shared Infrastructure Module** (`modules/`)

**Purpose:** Creates core AWS resources shared by all services

**Components:**
- **Network Module** (`modules/network/`)
  - VPC with CIDR `10.0.0.0/16`
  - 2 Public subnets (for EC2, NAT)
  - 2 Private subnets (for RDS)
  - Internet Gateway
  - Route tables

- **Backend Module** (`modules/backend/`)
  - EC2 instance (t3.small, Amazon Linux 2)
  - Elastic IP (static IP address)
  - Security groups (SSH, HTTP, HTTPS, app ports)
  - IAM roles and instance profile
  - Auto-generated SSH key pair
  - User data script (installs Docker, Nginx, Certbot)

- **Database Module** (`modules/database/`)
  - RDS PostgreSQL 17.4 (db.t3.small)
  - 20GB GP3 storage
  - Database subnet group
  - Security group (port 5432)
  - Parameter group with SSL enforcement

- **S3 Module** (`modules/s3/`)
  - Media storage bucket
  - CloudFront distribution for S3
  - VPC Gateway Endpoint (cost optimization)
  - IAM policies for EC2 access

- **CI/CD Module** (`modules/cicd/`)
  - CodePipeline (Source → Build → Deploy)
  - CodeBuild project
  - CodeDeploy application
  - ECR repository
  - S3 artifacts bucket
  - IAM roles

### 2. **Frontend Module** (`modules/frontend/`)

**Purpose:** Hosts React application with global CDN

**Components:**
- S3 bucket for static files
- CloudFront distribution
- Custom domain support
- ACM certificate integration
- Route 53 A records

### 3. **ACM Certificate Module** (`modules/acm-certificate/`)

**Purpose:** Manages SSL/TLS certificates and DNS

**Components:**
- Route 53 hosted zone
- ACM certificate (us-east-1 for CloudFront)
- DNS validation records
- A record for API subdomain (api.domain.com)

### 4. **Frontend CI/CD Module** (`modules/frontend-cicd/`)

**Purpose:** Automated frontend deployment pipeline

**Components:**
- CodePipeline for React app
- CodeBuild with Vite/React build
- S3 deployment
- CloudFront invalidation

### 5. **Backend CI/CD Modules** (Multiple instances)

**Purpose:** Separate pipeline for each backend service

**Services:**
- `geo_authback_cicd` - Flask authentication (port 5002)
- `geo_secondback_cicd` - Flask reports (port 5000)
- `geo_thirdback_cicd` - Flask service (port 5001)
- Primary backend (Django) - Integrated in shared infrastructure

---

## Deployment Guide

### Full Deployment Process

#### Step 1: Deploy Infrastructure

```bash
cd stacks/geo/development

# Deploy everything
terraform apply
```

**What happens:**
1. VPC and networking created
2. EC2 instance launched with Elastic IP
3. RDS PostgreSQL database created
4. S3 buckets created
5. ACM certificate requested (5-30 min validation)
6. CloudFront distribution created
7. CI/CD pipelines created for all services
8. Nginx + Certbot installed on EC2 (automated)

**Timeline:**
- Initial apply: ~10-15 minutes
- ACM certificate validation: 5-30 minutes
- SSL certificate automation: 15-60 minutes (after DNS)

#### Step 2: Configure Domain Nameservers

```bash
# Get nameservers
terraform output nameservers
```

**Output example:**
```
[
  "ns-1530.awsdns-63.org",
  "ns-1761.awsdns-28.co.uk",
  "ns-688.awsdns-22.net",
  "ns-98.awsdns-12.com"
]
```

**Configure in domain registrar:**
1. Login to your registrar (OVH, GoDaddy, etc.)
2. Find DNS/Nameserver settings
3. Replace existing nameservers with the 4 AWS nameservers
4. Save changes

**Wait 15-60 minutes for DNS propagation**

#### Step 3: Approve CodeStar Connection

The GitHub integration requires one-time manual approval:

1. Open AWS Console
2. Navigate to **Developer Tools** → **Connections**
3. Find connection (status: PENDING)
4. Click **"Update pending connection"**
5. **Authorize GitHub** access

#### Step 4: Monitor SSL Certificate Setup

The EC2 instance automatically sets up SSL for all API subdomains:

```bash
# SSH to EC2
ssh -i ./geo-dev-backend-key.pem ec2-user@$(terraform output -raw backend_elastic_ip)

# Check SSL setup progress
sudo tail -f /var/log/ssl-cert-setup.log

# Check service status
sudo systemctl status ssl-cert-setup.service
sudo systemctl status nginx

# Verify all domains are in the certificate
sudo certbot certificates
```

**Automation waits for:**
1. DNS propagation for all 4 domains (api, api1, api2, api3)
2. Obtains single Let's Encrypt certificate covering all domains
3. Configures Nginx with HTTPS for all 4 subdomains
4. Self-disables after success

#### Step 5: Verify Deployment

```bash
# Get all important URLs
terraform output application_urls

# Test frontend
curl -I https://sabeeltech-esg.dev

# Test backend APIs (all HTTPS)
curl -I https://api.sabeeltech-esg.dev
curl -I https://api1.sabeeltech-esg.dev
curl -I https://api2.sabeeltech-esg.dev
curl -I https://api3.sabeeltech-esg.dev
```

---

## Post-Deployment Configuration

### Update Frontend Configuration

Your React app automatically uses HTTPS API endpoints via the CI/CD pipeline:

```javascript
// For Vite projects
// .env (automatically injected by CodeBuild)
VITE_AUTH_BACKEND_URL=https://api.sabeeltech-esg.dev
VITE_MAIN_BACKEND_URL=https://api1.sabeeltech-esg.dev
VITE_SECOND_BACKEND_URL=https://api2.sabeeltech-esg.dev
VITE_THIRD_BACKEND_URL=https://api3.sabeeltech-esg.dev
```

**Note:** All backend APIs now use HTTPS with SSL certificates via Nginx reverse proxy and Let's Encrypt.

### Deploy Applications

Each service has its own CodePipeline:

**Trigger deployment:**
1. Push code to GitHub repository
2. CodePipeline automatically triggers
3. CodeBuild builds Docker image
4. Image pushed to ECR
5. CodeDeploy deploys to EC2

**Manual trigger:**
```bash
# Via AWS CLI
aws codepipeline start-pipeline-execution \
  --name geo-dev-geoinvestinsights-authback-pipeline \
  --profile geo
```

### Access EC2 Instance

```bash
# SSH connection
ssh -i ./geo-dev-backend-key.pem ec2-user@$(terraform output -raw backend_elastic_ip)

# Check running containers
sudo docker ps

# View logs
sudo docker logs geo-authback
sudo docker logs geo-backend
```

### Database Access

**Via SSH Tunnel:**
```bash
# Create tunnel
ssh -i ./geo-dev-backend-key.pem -L 5432:DATABASE_ENDPOINT:5432 ec2-user@ELASTIC_IP

# Connect with psql
psql -h localhost -p 5432 -U postgres -d geo_dev
```

---

## Destroy and Recreate

### Full Destroy/Apply Cycle

**Will everything work after `terraform destroy` + `terraform apply`?**

✅ **YES! Almost everything is fully automated.**

#### What Works Automatically

1. ✅ **Elastic IP** - Recreated and attached
2. ✅ **Route 53 & DNS** - Hosted zone and A records for all 4 API subdomains recreated
3. ✅ **ACM Certificate** - Recreated and validated automatically
4. ✅ **Let's Encrypt SSL** - Automated systemd service obtains certificate for all 4 domains
5. ✅ **CloudFront** - Recreated with custom domain
6. ✅ **Nginx Configuration** - All 4 API subdomains configured with HTTPS
7. ✅ **All Modules** - Recreated exactly as configured

#### Manual Steps Required

1. **Update Nameservers** (they change when hosted zone is recreated)
   ```bash
   terraform output nameservers
   # Update in domain registrar
   ```

2. **Approve CodeStar Connection**
   - AWS Console → Developer Tools → Connections
   - Update pending connection → Authorize GitHub

#### ⚠️ Data Loss Warning

These are **DESTROYED** and **NOT recoverable**:
- ❌ RDS Database (all data lost)
- ❌ S3 bucket contents (all files lost)
- ❌ EC2 state (logs, configurations lost)

**Backup before destroy:**
```bash
# Backup database
pg_dump -h DB_ENDPOINT -U postgres -d geo_dev > backup.sql

# Backup S3
aws s3 sync s3://bucket-name local-backup/ --profile geo
```

#### Destroy/Apply Steps

```bash
cd stacks/geo/development

# 1. Destroy everything
terraform destroy

# 2. Apply everything
terraform apply

# 3. Update nameservers in domain registrar
terraform output nameservers

# 4. Wait 15-60 minutes for DNS propagation

# 5. Approve CodeStar connection in AWS Console

# 6. Verify SSL setup
ssh -i ./geo-dev-backend-key.pem ec2-user@$(terraform output -raw backend_elastic_ip)
sudo tail -f /var/log/ssl-cert-setup.log

# 7. Test all endpoints
curl -I https://sabeeltech-esg.dev
curl -I https://api.sabeeltech-esg.dev
curl -I https://api1.sabeeltech-esg.dev
curl -I https://api2.sabeeltech-esg.dev
curl -I https://api3.sabeeltech-esg.dev
```

**Timeline:**
- Terraform apply: ~10-15 minutes
- ACM validation: 5-30 minutes
- DNS propagation: 15-60 minutes (after nameserver update)
- SSL automation: Happens automatically once DNS works
- **Total: ~60-90 minutes**

---

## Troubleshooting

### Certificate Not Validating

**Symptoms:** ACM certificate stuck in "Pending validation"

**Solutions:**
1. Wait 5-30 minutes for DNS propagation
2. Check nameservers in domain registrar
3. Verify DNS validation records in Route 53 console

```bash
# Check certificate status
aws acm describe-certificate \
  --certificate-arn $(terraform output -raw certificate_arn) \
  --region us-east-1 \
  --profile geo
```

### Frontend Domain Not Resolving

**Symptoms:** `nslookup sabeeltech-esg.dev` fails

**Solutions:**
1. Wait 15-60 minutes after updating nameservers
2. Clear local DNS cache:
   ```bash
   # Linux
   sudo systemd-resolve --flush-caches

   # macOS
   sudo dscacheutil -flushcache

   # Windows
   ipconfig /flushdns
   ```
3. Check with different DNS server:
   ```bash
   nslookup sabeeltech-esg.dev 8.8.8.8
   ```

### SSL Certificate Not Obtained

**Symptoms:** HTTPS not working for api subdomains (`ERR_CERT_COMMON_NAME_INVALID`)

**Solutions:**
1. Check DNS resolution for all domains:
   ```bash
   nslookup api.sabeeltech-esg.dev
   nslookup api1.sabeeltech-esg.dev
   nslookup api2.sabeeltech-esg.dev
   nslookup api3.sabeeltech-esg.dev
   ```
2. Check SSL setup logs:
   ```bash
   ssh -i ./geo-dev-backend-key.pem ec2-user@ELASTIC_IP
   sudo cat /var/log/ssl-cert-setup.log
   ```
3. Verify certificate includes all domains:
   ```bash
   sudo certbot certificates
   ```
4. Manually re-obtain certificate if needed:
   ```bash
   sudo systemctl stop nginx
   sudo certbot delete --cert-name api.sabeeltech-esg.dev --non-interactive
   sudo certbot certonly --standalone --preferred-challenges http \
       -d api.sabeeltech-esg.dev \
       -d api1.sabeeltech-esg.dev \
       -d api2.sabeeltech-esg.dev \
       -d api3.sabeeltech-esg.dev \
       --non-interactive --agree-tos --email admin@sabeeltech-esg.dev
   sudo systemctl start nginx
   ```

### Backend API Not Accessible

**Symptoms:** Cannot connect to backend services

**Solutions:**
1. **Check Security Group:**
   ```bash
   aws ec2 describe-security-groups \
     --filters "Name=tag:Name,Values=geo-dev-backend-sg" \
     --profile geo
   ```
   Verify ports 22, 80, 443, 5000, 5001, 5002, 8000 are open

2. **Check Services Running:**
   ```bash
   ssh -i ./geo-dev-backend-key.pem ec2-user@ELASTIC_IP
   sudo docker ps
   ```

3. **Check Container Logs:**
   ```bash
   sudo docker logs geo-authback
   sudo docker logs geo-backend
   ```

4. **Restart Container:**
   ```bash
   sudo docker restart geo-authback
   ```

### CodePipeline Failing

**Symptoms:** Pipeline execution fails

**Solutions:**
1. **Check Pipeline Status:**
   ```bash
   aws codepipeline get-pipeline-execution \
     --pipeline-name geo-dev-geoinvestinsights-authback-pipeline \
     --profile geo
   ```

2. **Check CodeBuild Logs:**
   - AWS Console → CodeBuild → Build History
   - Click on failed build → View logs

3. **Common Issues:**
   - `buildspec.yml` not found → Check repository root
   - Docker build fails → Check Dockerfile syntax
   - Insufficient permissions → Check IAM roles

### Database Connection Issues

**Symptoms:** Applications can't connect to database

**Solutions:**
1. **Check Database Endpoint:**
   ```bash
   terraform output database_endpoint
   ```

2. **Verify Security Group:**
   ```bash
   aws ec2 describe-security-groups \
     --filters "Name=tag:Name,Values=geo-dev-database-sg" \
     --profile geo
   ```
   Ensure port 5432 allows traffic from EC2 security group

3. **Test Connection from EC2:**
   ```bash
   ssh -i ./geo-dev-backend-key.pem ec2-user@ELASTIC_IP
   psql -h DATABASE_ENDPOINT -U postgres -d geo_dev
   ```

### Terraform State Issues

**Symptoms:** "Resource already exists" or state drift

**Solutions:**
```bash
# View state
terraform state list

# Remove specific resource
terraform state rm 'module.path.to.resource'

# Import existing resource
terraform import 'module.path.to.resource' resource-id

# Refresh state
terraform refresh
```

---

## Cost Breakdown

### Monthly Cost Estimate (Development)

| Service | Resource | Cost |
|---------|----------|------|
| **Compute** | EC2 t3.small (24/7) | ~$15/month |
| **Database** | RDS t3.small (24/7) | ~$25/month |
| **Storage** | S3 Standard (10GB) | ~$0.23/month |
| **Network** | Elastic IP (attached) | $0.00/month |
| **Network** | Data Transfer (10GB out) | ~$0.90/month |
| **DNS** | Route 53 Hosted Zone | $0.50/month |
| **DNS** | Route 53 Queries (1M) | ~$0.40/month |
| **CDN** | CloudFront (10GB) | ~$0.85/month |
| **CDN** | CloudFront Requests (1M) | ~$0.10/month |
| **SSL** | ACM Certificate | $0.00/month |
| **SSL** | Let's Encrypt | $0.00/month |
| **CI/CD** | CodeBuild (100 min/month) | ~$1.00/month |
| **CI/CD** | CodePipeline (5 pipelines) | $5.00/month |
| **Container Registry** | ECR Storage (5GB) | ~$0.50/month |
| **Total** | | **~$50/month** |

### Cost Optimization Tips

1. **Stop EC2 when not in use:**
   ```bash
   aws ec2 stop-instances --instance-ids i-xxxxx --profile geo
   ```
   Note: Elastic IP charges $0.005/hour when not attached

2. **Use Auto-Scaling for RDS:**
   - Set minimum storage to 20GB
   - Enable storage auto-scaling

3. **Implement S3 Lifecycle Policies:**
   - Delete old artifacts after 7 days
   - Move media files to S3 Glacier after 30 days

4. **Use CloudFront Price Class:**
   - PriceClass_100 (cheapest) for dev
   - PriceClass_200 for production

---

## Additional Resources

### Terraform Outputs

```bash
# View all outputs
terraform output

# Specific outputs
terraform output backend_elastic_ip
terraform output database_endpoint
terraform output application_urls
terraform output nameservers
terraform output ssh_connection_command
```

### Useful AWS CLI Commands

```bash
# List EC2 instances
aws ec2 describe-instances --profile geo

# List RDS instances
aws rds describe-db-instances --profile geo

# List S3 buckets
aws s3 ls --profile geo

# List CodePipelines
aws codepipeline list-pipelines --profile geo

# View CloudFront distributions
aws cloudfront list-distributions --profile geo
```

### SSH Commands

```bash
# Connect to EC2
ssh -i ./geo-dev-backend-key.pem ec2-user@ELASTIC_IP

# Database tunnel
ssh -i ./geo-dev-backend-key.pem -L 5432:DB_ENDPOINT:5432 ec2-user@ELASTIC_IP

# Copy files to EC2
scp -i ./geo-dev-backend-key.pem file.txt ec2-user@ELASTIC_IP:/home/ec2-user/
```

---

## Support & Contribution

### Getting Help

1. Check this README thoroughly
2. Review AWS Console for error messages
3. Check Terraform state and plan output
4. Review application logs on EC2

### Project Structure

```
terraform-infra-python/
├── modules/                    # Reusable Terraform modules
│   ├── network/               # VPC, subnets, routing
│   ├── backend/               # EC2, security groups, IAM
│   ├── database/              # RDS PostgreSQL
│   ├── s3/                    # S3 buckets, CloudFront
│   ├── cicd/                  # CodePipeline, Build, Deploy
│   ├── frontend/              # S3 + CloudFront for React
│   ├── frontend-cicd/         # React deployment pipeline
│   └── acm-certificate/       # Route 53, ACM, DNS
├── stacks/
│   └── geo/
│       └── development/       # Development environment
│           ├── main.tf        # Module composition
│           ├── variables.tf   # Input variables
│           ├── outputs.tf     # Output values
│           ├── providers.tf   # AWS provider config
│           └── terraform.tfvars  # Variable values (gitignored)
└── README.md                  # This file
```

---

## License

This infrastructure code is proprietary. All rights reserved.

---

**Last Updated:** 2025-09-30
