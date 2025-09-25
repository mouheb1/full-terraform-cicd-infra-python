# Geo Terraform Infrastructure

This repository contains the complete AWS infrastructure setup for the **GeoInvestInsights** project, a cost-optimized cloud architecture for hosting multiple Python applications (Django + Flask backends) with PostgreSQL database and media storage capabilities.

## Infrastructure Overview

The infrastructure is designed for a multi-backend 3-tier architecture pattern with focus on cost optimization while maintaining security and scalability. Multiple dockerized Python backends share the same EC2 instance while maintaining separate CI/CD pipelines.

## AWS Services Used

### Core Compute Services
- **EC2 Instance** (`t3.micro`)
  - Amazon Linux 2 AMI
  - Auto-configured for multiple dockerized Python applications (Django + Flask)
  - Includes CodeDeploy agent for automated deployments
  - Security groups configured for HTTP/HTTPS (80, 443), SSH (22), and application ports (8000, 5000)
  - IAM role with ECR, S3, and CloudWatch Logs permissions
  - Supports multiple Docker containers on the same instance

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
- **Multiple CodePipelines** (one per backend)
  - 3-stage pipeline: Source → Build → Deploy
  - **CodeStar Connection** for GitHub integration
  - **CodeBuild** project with `BUILD_GENERAL1_SMALL` compute type
  - **CodeDeploy** application for EC2 deployment
  - **ECR Repository** for Docker container images (separate repo per backend)
  - Lifecycle policies to cleanup old images (keep last 3 tagged, delete untagged after 1 day)
  - S3 artifact storage with automatic cleanup (7-day expiration)
  - **Backend Pipelines**:
    - `Primary Backend`: Django application (geoinvestinsights-backend) - integrated with shared infrastructure
    - `geo_secondback`: Flask application (geoinvestinsights-secondback) - separate CI/CD module

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

### Development Environment (`geo/development/`)
- **Region**: `eu-west-3` (Paris)
- **VPC CIDR**: `10.0.0.0/16`
- **Instance Type**: `t3.micro`
- **Database**: `geo_dev` with development settings
- **GitHub Repositories**:
  - `sabeel-it-consulting/geoinvestinsights-backend` (Django backend)
  - `sabeel-it-consulting/geoinvestinsights-secondback` (Flask backend)
- **Branch**: `main`

### Application Configuration
- **Python Environment**: `development`
- **Backend Applications**:
  - **Primary Backend** (Django): Port `8000`, full-stack web application
  - **geo_secondback** (Flask): Port `5000`, API service for reports
- **Database Connection**: Via environment variables (shared between backends)
- **Django Configuration**: Secret key and security settings
- **S3 Integration**: For media file storage and retrieval (shared across backends)

## Key Features

1. **Multi-Backend Architecture**: Support for multiple dockerized Python applications on single EC2 instance
2. **Automated Deployment**: Separate CI/CD pipelines for each backend from GitHub to EC2
3. **Database Connectivity**: SSH tunnel support for secure database access (shared across backends)
4. **Media Storage**: S3 + CloudFront for optimized media delivery (shared across backends)
5. **Security**: VPC isolation, security groups, IAM roles
6. **Cost-Optimized**: Multiple applications sharing infrastructure for maximum cost efficiency
7. **Container Orchestration**: Docker-based deployment with separate ECR repositories
8. **Monitoring**: CloudWatch integration for logs and metrics across all backends
9. **SSL/TLS**: HTTPS support with security group configurations

## Infrastructure Outputs

The infrastructure provides the following key outputs:
- VPC ID and networking details
- EC2 instance public IP and DNS
- Database endpoint and connection details
- SSH connection commands and tunnel setup
- ECR repository URL for container images
- CodePipeline name for CI/CD monitoring

This infrastructure setup provides a complete, production-ready foundation for multiple Python applications (Django + Flask) with PostgreSQL backend and media storage capabilities, optimized for cost-effectiveness while maintaining security best practices and supporting multi-backend deployments on shared infrastructure.

## Multi-Backend Implementation Details

### Enhanced Architecture Overview
The infrastructure uses an **improved shared resource model** with **parameterized modules** to prevent resource duplication conflicts:

- **Shared Infrastructure Module**: Creates all core AWS resources (VPC, EC2, RDS, S3, networking) once
- **Parameterized CI/CD Modules**: Create separate deployment pipelines for each backend with unique identifiers
- **Single EC2 Instance**: All Docker containers deploy to the same `t3.micro` instance
- **No Resource Conflicts**: Each backend uses unique naming (`backend_name` parameter) to prevent "already exists" errors
- **Independent Deployments**: Each backend maintains separate CodePipeline, ECR, and deployment processes

### Current Backends
- **Primary Backend** (Django): Main web application
  - Repository: `sabeel-it-consulting/geoinvestinsights-backend`
  - Container: Runs on port 8000
  - Backend Name: `backend`
  - Purpose: Full-stack Django application with admin interface
  - CI/CD: Integrated with shared infrastructure module

- **Secondary Backend** (Flask): Reports API service  
  - Repository: `sabeel-it-consulting/geoinvestinsights-secondback`
  - Container: Runs on port 5000
  - Backend Name: `secondback`
  - Purpose: Flask API service for generating reports (`RapportRest.py`)
  - CI/CD: Separate parameterized pipeline module

### Key Parameterization Features
- **`backend_name`**: Unique identifier prevents resource naming conflicts
- **`application_port`**: Allows different ports per backend (8000, 5000, 3000, etc.)
- **`codestar_connection_arn`**: Reuses GitHub connection across all backends
- **Per-Backend Resources**: ECR repositories, CodePipelines, and S3 artifacts buckets are unique per backend
- **Shared Resources**: VPC, EC2, RDS, security groups, and networking are created once and reused

### Adding New Backends
To add additional backends without conflicts:

```hcl
module "geo_[name]_cicd" {
  source               = "../../../modules/cicd"
  environment          = "dev"
  namespace            = "geo"
  backend_name         = "[unique-name]"        # Prevents naming conflicts
  application_port     = [unique-port]          # e.g., 8080, 3000, 5001
  
  github_repo          = "[repository-name]"
  github_owner         = "sabeel-it-consulting"
  github_branch        = "main"

  # Reuse shared resources - no duplication
  backend_instance_id     = module.shared_infrastructure.backend_instance_id
  codestar_connection_arn = module.shared_infrastructure.codestar_connection_arn

  tags = {
    namespace = "geo"
    backend   = "[name]"
  }
}
```

### Infrastructure Sharing Model
- **Shared Resources** (created once): EC2, VPC, RDS, S3, security groups, networking, CodeStar connection
- **Per-Backend Resources** (created per backend): ECR repository, CodePipeline, CodeBuild, CodeDeploy application, S3 artifacts bucket
- **Resource Isolation**: Each backend has unique CI/CD pipeline while sharing target infrastructure
- **Cost Optimization**: Maximum resource sharing while maintaining deployment independence
