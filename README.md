# Geo Terraform Infrastructure

This repository contains the complete AWS infrastructure setup for the **GeoInvestInsights** project, a cost-optimized cloud architecture for hosting Django Python applications with PostgreSQL database and media storage capabilities.

## Infrastructure Overview

The infrastructure is designed for a 3-tier architecture pattern with focus on cost optimization while maintaining security and scalability.

## AWS Services Used

### Core Compute Services
- **EC2 Instance** (`t3.micro`)
  - Amazon Linux 2 AMI
  - Auto-configured for Django Python application deployment
  - Includes CodeDeploy agent for automated deployments
  - Security groups configured for HTTP/HTTPS (80, 443), SSH (22), and application port (8000)
  - IAM role with ECR, S3, and CloudWatch Logs permissions

### Networking Infrastructure
- **VPC** (Virtual Private Cloud)
  - Custom VPC with `10.0.0.0/16` CIDR block
  - DNS hostnames and DNS support enabled
  - **Internet Gateway** for public internet access
  - **Public Subnets** (2 AZs) with auto-assign public IPs
  - **Private Subnets** (2 AZs) for database and internal services
  - Route tables configured for proper traffic routing

### Database Services
- **RDS PostgreSQL** (`db.t3.micro`)
  - PostgreSQL 17.4 engine
  - 20GB GP3 storage (cost-optimized)
  - Multi-AZ disabled for cost savings
  - Backup retention: 0 days (development optimized)
  - Custom parameter group with SSL enforcement
  - Private subnet deployment with security group restrictions
  - Database subnet group across multiple AZs

### Storage Services
- **S3 Bucket** (Media Storage)
  - Cost-optimized configuration with lifecycle policies
  - Server-side encryption with AES256
  - Public access blocked for security
  - Environment-aware file expiration (30 days in dev, permanent in prod)
  - **CloudFront Distribution** for global content delivery
  - Origin Access Control (OAC) for secure S3 access
  - **VPC Gateway Endpoint** for S3 (eliminates data transfer costs)

### CI/CD Pipeline
- **CodePipeline**
  - 3-stage pipeline: Source → Build → Deploy
  - **CodeStar Connection** for GitHub integration
  - **CodeBuild** project with `BUILD_GENERAL1_SMALL` compute type
  - **CodeDeploy** application for EC2 deployment
  - **ECR Repository** for Docker container images
  - Lifecycle policies to cleanup old images (keep last 3 tagged, delete untagged after 1 day)
  - S3 artifact storage with automatic cleanup (7-day expiration)

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
- **EC2**: t3.micro instance, 8GB GP3 storage, no encryption
- **RDS**: t3.micro instance, minimal storage, no backups, no Multi-AZ
- **S3**: Lifecycle policies, no versioning, standard storage class
- **CloudFront**: PriceClass_100 for development environments
- **ECR**: Aggressive image cleanup policies
- **CodePipeline**: Artifact cleanup after 7 days

## Environment Configuration

### Development Environment (`serbini/development/`)
- **Region**: `eu-west-3` (Paris)
- **VPC CIDR**: `10.0.0.0/16`
- **Instance Type**: `t3.micro`
- **Database**: `serbini_dev` with development settings
- **GitHub Repository**: `mouheb1/geoinvestinsights-backend`
- **Branch**: `main`

### Application Configuration
- **Python Environment**: `development`
- **Application Port**: `8000` (Django default)
- **Database Connection**: Via environment variables
- **Django Configuration**: Secret key and security settings
- **S3 Integration**: For media file storage and retrieval

## Key Features

1. **Automated Deployment**: Complete CI/CD pipeline from GitHub to EC2
2. **Database Connectivity**: SSH tunnel support for secure database access
3. **Media Storage**: S3 + CloudFront for optimized media delivery
4. **Security**: VPC isolation, security groups, IAM roles
5. **Cost-Optimized**: Minimal resource allocation suitable for development/small production
6. **Monitoring**: CloudWatch integration for logs and metrics
7. **SSL/TLS**: HTTPS support with security group configurations

## Infrastructure Outputs

The infrastructure provides the following key outputs:
- VPC ID and networking details
- EC2 instance public IP and DNS
- Database endpoint and connection details
- SSH connection commands and tunnel setup
- ECR repository URL for container images
- CodePipeline name for CI/CD monitoring

This infrastructure setup provides a complete, production-ready foundation for Django Python applications with PostgreSQL backend and media storage capabilities, optimized for cost-effectiveness while maintaining security best practices.
