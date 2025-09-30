# Geo Terraform Infrastructure

This repository contains the complete AWS infrastructure setup for the **GeoInvestInsights** project, a cost-optimized full-stack cloud architecture for hosting multiple Python applications (Django + Flask backends), a React frontend, PostgreSQL database, and media storage capabilities.

## Infrastructure Overview

The infrastructure is designed for a comprehensive multi-tier architecture pattern with focus on cost optimization while maintaining security and scalability. The setup includes:
- **4 Backend Services**: Django + 3 Flask microservices sharing the same EC2 instance
- **React Frontend**: Hosted on S3 with CloudFront distribution
- **Dedicated CI/CD Pipelines**: Separate deployment pipelines for each service
- **Shared Infrastructure**: Database, networking, and storage shared across all services

## AWS Services Used

### Core Compute Services
- **EC2 Instance** (`t3.small`)
  - Amazon Linux 2 AMI
  - Auto-configured for 4 dockerized Python applications (1 Django + 3 Flask)
  - Includes CodeDeploy agent for automated deployments
  - Security groups configured for HTTP/HTTPS (80, 443), SSH (22), and application ports (8000, 5000, 5001, 5002)
  - IAM role with ECR, S3, and CloudWatch Logs permissions
  - Supports multiple Docker containers on the same instance with different port mappings

### Networking Infrastructure
- **VPC** (Virtual Private Cloud)
  - Custom VPC with `10.0.0.0/16` CIDR block
  - DNS hostnames and DNS support enabled
  - **Internet Gateway** for public internet access
  - **Public Subnets** (2 AZs) with auto-assign public IPs
  - **Private Subnets** (2 AZs) for database and internal services
  - Route tables configured for proper traffic routing

### Database Services
- **RDS PostgreSQL** (`db.t3.small`)
  - PostgreSQL 17.4 engine
  - 20GB GP3 storage (cost-optimized)
  - Multi-AZ disabled for cost savings
  - Backup retention: 0 days (development optimized)
  - Custom parameter group with SSL enforcement
  - Private subnet deployment with security group restrictions
  - Database subnet group across multiple AZs

### Storage Services
- **S3 Buckets** (Multiple)
  - **Media Storage Bucket**: Backend file storage with lifecycle policies
  - **Frontend Hosting Bucket**: React application static files
  - Server-side encryption with AES256
  - Public access blocked for security
  - Environment-aware file expiration (30 days in dev, permanent in prod)
  - **CloudFront Distributions** for global content delivery
  - Origin Access Control (OAC) for secure S3 access
  - **VPC Gateway Endpoint** for S3 (eliminates data transfer costs)

### CI/CD Pipeline
- **Multiple CodePipelines** (one per service: 4 backends + 1 frontend)
  - 3-stage pipeline: Source → Build → Deploy
  - **CodeStar Connection** for GitHub integration
  - **CodeBuild** project with `BUILD_GENERAL1_SMALL` compute type
  - **CodeDeploy** applications for deployments
  - **ECR Repositories** for Docker container images (separate repo per backend)
  - Lifecycle policies to cleanup old images (keep last 3 tagged, delete untagged after 1 day)
  - S3 artifact storage with automatic cleanup (7-day expiration)
  - **Backend Pipelines**:
    - `geoinvestinsights-backend`: Django application (Port 8000) - Main web application
    - `geoinvestinsights-authback`: Flask authentication service (Port 5002)
    - `geoinvestinsights-secondback`: Flask reports service (Port 5000)
    - `geoinvestinsights-thirdback`: Flask additional service (Port 5001)
  - **Frontend Pipeline**:
    - `geoinvestinsights-frontend`: React application - S3 + CloudFront deployment

### Security & Access Management
- **IAM Roles & Policies**
  - EC2 instance role with S3, ECR, and CloudWatch permissions
  - CodeBuild service role with necessary build permissions
  - CodePipeline service role with cross-service access
  - CodeDeploy service role with deployment permissions
  - S3 access policy for EC2 instances
- **Security Groups**
  - Backend security group (HTTP, HTTPS, SSH, app port)
  - Database security group (PostgreSQL port 5432, restricted to backend)
- **SSH Key Pairs**
  - Auto-generated RSA 4096-bit key pairs
  - Private key stored locally with 0400 permissions

### Cost Optimization Features
- **EC2**: t3.small instance, 8GB GP3 storage, no encryption
- **RDS**: t3.small instance, minimal storage, no backups, no Multi-AZ
- **S3**: Lifecycle policies, no versioning, standard storage class
- **CloudFront**: PriceClass_100 for development environments
- **ECR**: Aggressive image cleanup policies
- **CodePipeline**: Artifact cleanup after 7 days

## Environment Configuration

### Development Environment (`geo/development/`)
- **Region**: `eu-west-3` (Paris)
- **VPC CIDR**: `10.0.0.0/16`
- **Instance Type**: `t3.small`
- **Database**: `geo_dev` with development settings
- **GitHub Repositories**:
  - `sabeel-it-consulting/geoinvestinsights-backend` (Django main backend)
  - `sabeel-it-consulting/geoinvestinsights-authback` (Flask auth service)
  - `sabeel-it-consulting/geoinvestinsights-secondback` (Flask reports service)
  - `sabeel-it-consulting/geoinvestinsights-thirdback` (Flask additional service)
  - `sabeel-it-consulting/geoinvestinsights-frontend` (React frontend)
- **Branch**: `main`

### Application Configuration
- **Python Environment**: `development`
- **Backend Applications**:
  - **geoinvestinsights-backend** (Django): Port `8000` - Main web application with admin interface
  - **geoinvestinsights-authback** (Flask): Port `5002` - Authentication and user management service
  - **geoinvestinsights-secondback** (Flask): Port `5000` - Reports generation service
  - **geoinvestinsights-thirdback** (Flask): Port `5001` - Additional microservice
- **Frontend Application**:
  - **geoinvestinsights-frontend** (React): Static hosting via S3 + CloudFront
- **Database Connection**: PostgreSQL via environment variables (shared across all backends)
- **Django Configuration**: Secret key and security settings
- **JWT Authentication**: Shared authentication across Flask services
- **S3 Integration**: Media file storage and React app hosting

## Key Features

1. **Full-Stack Architecture**: Complete application stack with React frontend and multiple Python backends
2. **Microservices Architecture**: 4 backend services (1 Django + 3 Flask) with service-specific responsibilities
3. **Automated Deployment**: Separate CI/CD pipelines for each service (4 backends + 1 frontend)
4. **Frontend Hosting**: React application with S3 + CloudFront for global CDN delivery
5. **Database Connectivity**: Shared PostgreSQL database with SSH tunnel support for secure access
6. **Media Storage**: Dual S3 buckets for backend media files and frontend static assets
7. **Security**: VPC isolation, security groups, IAM roles, and SSL/TLS support
8. **Cost-Optimized**: Shared infrastructure with independent deployments for maximum efficiency
9. **Container Orchestration**: Docker-based backend deployment with separate ECR repositories
10. **Monitoring**: CloudWatch integration for comprehensive logging and metrics
11. **Port Management**: Strategic port allocation (8000, 5000, 5001, 5002) for service isolation

## Infrastructure Outputs

The infrastructure provides the following key outputs:
- **Networking**: VPC ID, public/private subnet IDs
- **Compute**: EC2 instance public IP and DNS name
- **Database**: PostgreSQL endpoint, port, and connection details
- **Storage**: S3 bucket names and CloudFront distribution URLs
- **CI/CD**: ECR repository URLs and CodePipeline names for all services
- **Security**: SSH connection commands and database tunnel setup
- **Frontend**: CloudFront domain names and distribution IDs

This infrastructure setup provides a complete, production-ready foundation for a full-stack application with React frontend, multiple Python backends (Django + Flask microservices), PostgreSQL database, and comprehensive media storage capabilities, optimized for cost-effectiveness while maintaining security best practices and supporting independent service deployments on shared infrastructure.

## Multi-Backend Implementation Details

### Enhanced Architecture Overview
The infrastructure uses an **improved shared resource model** with **parameterized modules** to prevent resource duplication conflicts:

- **Shared Infrastructure Module**: Creates all core AWS resources (VPC, EC2, RDS, S3, networking) once
- **Parameterized CI/CD Modules**: Create separate deployment pipelines for each backend with unique identifiers
- **Single EC2 Instance**: All Docker containers deploy to the same `t3.small` instance
- **No Resource Conflicts**: Each backend uses unique naming (`backend_name` parameter) to prevent "already exists" errors
- **Independent Deployments**: Each backend maintains separate CodePipeline, ECR, and deployment processes

### Current Services

#### Backend Services
- **Primary Backend** (Django): Main web application
  - Repository: `sabeel-it-consulting/geoinvestinsights-backend`
  - Container: Runs on port 8000
  - Backend Name: `geoinvestinsights-backend`
  - Purpose: Full-stack Django application with admin interface and main business logic
  - CI/CD: Integrated with shared infrastructure module

- **Authentication Backend** (Flask): User management service
  - Repository: `sabeel-it-consulting/geoinvestinsights-authback`
  - Container: Runs on port 5002
  - Backend Name: `geoinvestinsights-authback`
  - Purpose: Flask service handling authentication, user management, and JWT tokens
  - CI/CD: Separate parameterized pipeline module

- **Reports Backend** (Flask): Reports generation service
  - Repository: `sabeel-it-consulting/geoinvestinsights-secondback`
  - Container: Runs on port 5000
  - Backend Name: `geoinvestinsights-secondback`
  - Purpose: Flask API service for generating reports and analytics
  - CI/CD: Separate parameterized pipeline module

- **Additional Backend** (Flask): Extended functionality service
  - Repository: `sabeel-it-consulting/geoinvestinsights-thirdback`
  - Container: Runs on port 5001
  - Backend Name: `geoinvestinsights-thirdback`
  - Purpose: Flask service for additional business logic and features
  - CI/CD: Separate parameterized pipeline module

#### Frontend Service
- **React Frontend**: User interface application
  - Repository: `sabeel-it-consulting/geoinvestinsights-frontend`
  - Hosting: S3 bucket with CloudFront distribution
  - Purpose: React SPA providing the user interface for all backend services
  - CI/CD: Separate frontend deployment pipeline

### Key Parameterization Features
- **`backend_name`**: Unique identifier prevents resource naming conflicts
- **`application_port`**: Allows different ports per service (8000, 5000, 5001, 5002)
- **`codestar_connection_arn`**: Reuses GitHub connection across all services
- **Per-Service Resources**: ECR repositories, CodePipelines, and S3 artifacts buckets are unique per service
- **Shared Resources**: VPC, EC2, RDS, security groups, and networking are created once and reused
- **Frontend Resources**: Separate S3 bucket and CloudFront distribution for React app hosting

### Adding New Services
To add additional backend services without conflicts:

```hcl
module "geo_[name]_cicd" {
  source               = "../../../modules/cicd"
  environment          = "dev"
  namespace            = "geo"
  backend_name         = "geoinvestinsights-[name]"  # Prevents naming conflicts
  application_port     = [unique-port]               # e.g., 5003, 5004, 8080

  github_repo          = "geoinvestinsights-[name]"
  github_owner         = "sabeel-it-consulting"
  github_branch        = "main"

  # Reuse shared resources - no duplication
  backend_instance_id     = module.shared_infrastructure.backend_instance_id
  codestar_connection_arn = module.shared_infrastructure.codestar_connection_arn

  tags = {
    namespace = "geo"
    service   = "[name]"
  }

  depends_on = [module.shared_infrastructure]
}
```

### Infrastructure Sharing Model
- **Shared Resources** (created once): EC2, VPC, RDS, S3 media bucket, security groups, networking, CodeStar connection
- **Per-Backend Resources** (created per backend): ECR repository, CodePipeline, CodeBuild, CodeDeploy application, S3 artifacts bucket
- **Frontend Resources** (created once): S3 hosting bucket, CloudFront distribution, frontend CI/CD pipeline
- **Resource Isolation**: Each service has unique CI/CD pipeline while sharing target infrastructure
- **Cost Optimization**: Maximum resource sharing while maintaining deployment independence

### Deployment Order
For initial setup, deploy the shared infrastructure first:
```bash
terraform apply -target=module.shared_infrastructure -auto-approve
```

Then deploy additional services:
```bash
terraform apply -target=module.geo_secondback_cicd -auto-approve
terraform apply -target=module.geo_thirdback_cicd -auto-approve
terraform apply -target=module.geo_authback_cicd -auto-approve
terraform apply -target=module.geo_frontend -auto-approve
terraform apply -target=module.geo_frontend_cicd -auto-approve
```

## DNS Configuration (Optional)

The infrastructure supports custom domain configuration using Route 53 and OVH domains:

### Domain Setup
- **`api.yourdomain.com`** → EC2 instance (auth backend on port 5002)
- **`yourdomain.com`** → CloudFront distribution (React frontend)

### Configuration Steps
1. **Enable DNS in terraform.tfvars**:
   ```hcl
   domain_name    = "mydomain.com"
   enable_route53 = true
   ```

2. **Deploy and get nameservers**:
   ```bash
   terraform apply
   terraform output nameservers
   ```

3. **Configure OVH domain** to use Route 53 nameservers

4. **Wait for DNS propagation** (15-60 minutes)

### Auto-updating on EC2 IP Changes
When EC2 IP changes (stop/start):
1. Run `terraform apply`
2. Route 53 updates automatically
3. DNS propagation takes 1-2 minutes (TTL=60s)
4. Brief connectivity issues resolve automatically

For complete setup instructions, see [DNS_SETUP_GUIDE.md](DNS_SETUP_GUIDE.md).

### Cost Impact
- Route 53 Hosted Zone: **$0.50/month**
- DNS Queries: **~$0.40/month**
- **Total DNS cost: ~$1/month**