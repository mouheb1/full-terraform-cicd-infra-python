# Multi-Backend Deployment Guide

## Problem Solved
This guide explains how to deploy multiple dockerized Python backends on the same EC2 instance without encountering resource duplication errors like "subnet already exists" or similar Terraform conflicts.

## Architecture Overview

### Shared Resource Model
- **One EC2 Instance**: All backends deploy to the same `t3.micro` instance
- **Shared Infrastructure**: VPC, subnets, database, S3, security groups created once
- **Individual CI/CD**: Each backend gets its own CodePipeline, ECR, and deployment process
- **No Duplicates**: Network and core resources are never recreated

### Key Parameters Added
1. **`backend_name`**: Unique identifier for each backend (prevents resource naming conflicts)
2. **`application_port`**: Port where each backend runs (8000, 5000, 3000, etc.)
3. **`codestar_connection_arn`**: Reuse GitHub connection across backends

## How to Add New Backends

### Step 1: Create the Shared Infrastructure (Once Only)
```hcl
module "shared_infrastructure" {
  source        = "../../../modules"
  environment   = "dev"
  namespace     = "geo"
  # ... other configuration
  
  # Primary backend (Django)
  github_repo   = "geoinvestinsights-backend"
}
```

### Step 2: Add Additional Backends
For each new backend, add a new module block:

```hcl
module "geo_[BACKEND_NAME]_cicd" {
  source               = "../../../modules/cicd"
  environment          = "dev"
  namespace            = "geo"
  backend_name         = "[UNIQUE_NAME]"        # CRITICAL: Must be unique
  application_port     = [PORT_NUMBER]          # CRITICAL: Must be unique
  
  github_repo          = "[REPOSITORY_NAME]"
  github_owner         = "sabeel-it-consulting"
  github_branch        = "main"

  # REUSE shared resources - NO DUPLICATION
  backend_instance_id     = module.shared_infrastructure.backend_instance_id
  codestar_connection_arn = module.shared_infrastructure.codestar_connection_arn

  tags = {
    namespace = "geo"
    backend   = "[BACKEND_NAME]"
  }
}
```

## Current Backend Configuration

### Backend 1: Primary Django App
- **Name**: `backend` (primary)
- **Port**: `8000`
- **Repository**: `geoinvestinsights-backend`
- **Type**: Django web application
- **Created by**: Shared infrastructure module

### Backend 2: Flask Reports API
- **Name**: `secondback`
- **Port**: `5000`
- **Repository**: `geoinvestinsights-secondback`
- **Type**: Flask API service
- **Created by**: Separate CI/CD module

## Adding More Backends - Examples

### Example 1: FastAPI Data Processing Service
```hcl
module "geo_dataapi_cicd" {
  source               = "../../../modules/cicd"
  environment          = "dev"
  namespace            = "geo"
  backend_name         = "dataapi"              # Unique name
  application_port     = 8080                   # Unique port
  
  github_repo          = "geoinvestinsights-dataapi"
  github_owner         = "sabeel-it-consulting"
  github_branch        = "main"

  backend_instance_id     = module.shared_infrastructure.backend_instance_id
  codestar_connection_arn = module.shared_infrastructure.codestar_connection_arn

  tags = {
    namespace = "geo"
    backend   = "dataapi"
  }
}
```

### Example 2: Node.js WebSocket Service
```hcl
module "geo_websocket_cicd" {
  source               = "../../../modules/cicd"
  environment          = "dev"
  namespace            = "geo"
  backend_name         = "websocket"            # Unique name
  application_port     = 3000                   # Unique port
  
  github_repo          = "geoinvestinsights-websocket"
  github_owner         = "sabeel-it-consulting"
  github_branch        = "main"

  backend_instance_id     = module.shared_infrastructure.backend_instance_id
  codestar_connection_arn = module.shared_infrastructure.codestar_connection_arn

  tags = {
    namespace = "geo"
    backend   = "websocket"
  }
}
```

## What Gets Created Per Backend

### Shared Resources (Created Once)
- ✅ VPC and subnets
- ✅ EC2 instance
- ✅ RDS PostgreSQL database
- ✅ S3 bucket for media
- ✅ Security groups
- ✅ IAM roles for EC2
- ✅ CodeStar GitHub connection

### Per-Backend Resources (Created for Each)
- 🔄 ECR repository: `geo-dev-[backend_name]`
- 🔄 CodePipeline: `geo-dev-[backend_name]-pipeline`
- 🔄 CodeBuild project: `geo-dev-[backend_name]-build`
- 🔄 CodeDeploy application: `geo-dev-[backend_name]`
- 🔄 S3 artifacts bucket: `geo-dev-[backend_name]-artifacts-[random]`
- 🔄 IAM roles: `geo-dev-[backend_name]-codebuild-role`, etc.

## Deployment Process

1. **Deploy Shared Infrastructure**: Run `terraform apply` with shared_infrastructure module first
2. **Get Connection ARN**: Note the `codestar_connection_arn` output
3. **Add New Backend**: Add new CI/CD module with unique `backend_name` and `application_port`
4. **Deploy**: Run `terraform apply` - only new backend resources are created
5. **Verify**: Each backend gets its own ECR and pipeline but targets same EC2 instance

## Key Benefits

### ✅ No Resource Conflicts
- Unique naming prevents "already exists" errors
- Shared resources are never recreated
- Each backend has isolated CI/CD pipeline

### ✅ Cost Optimized
- Single EC2 instance hosts all backends
- Shared database, VPC, and networking
- Only CI/CD resources are duplicated (lightweight)

### ✅ Independent Deployments
- Each backend can be deployed independently
- Different GitHub repositories and branches
- Separate Docker containers and ports

### ✅ Scalable Architecture
- Add unlimited backends using same pattern
- Easy to remove backends (just remove module block)
- Each backend can use different programming languages/frameworks

## Important Notes

### Critical Parameters
- **`backend_name`**: Must be unique across all backends
- **`application_port`**: Must be unique across all backends
- **`codestar_connection_arn`**: Must reference shared infrastructure output

### Deployment Order
1. Deploy shared infrastructure first
2. Deploy additional backends in any order
3. All backends target the same EC2 instance

### Docker Container Management
- Each backend runs in its own Docker container
- Containers are managed by CodeDeploy on the EC2 instance
- Use different ports for each service
- Configure reverse proxy (nginx) if needed for routing

## Troubleshooting

### "Resource already exists" errors
- Check `backend_name` is unique
- Verify `application_port` is unique
- Ensure `codestar_connection_arn` references shared infrastructure

### "Connection not found" errors
- Deploy shared infrastructure first
- Check the connection ARN output is correctly referenced

### Port conflicts
- Ensure each backend uses a different `application_port`
- Update security groups if using non-standard ports
- Configure load balancer/reverse proxy for routing

This approach allows you to deploy unlimited Python backends (Django, Flask, FastAPI, etc.) on the same infrastructure without duplication conflicts while maintaining cost efficiency and deployment independence.