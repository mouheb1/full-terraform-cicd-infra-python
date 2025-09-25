#!/bin/bash

# Multi-Backend Deployment Helper Script
# This script helps you add new backends to your existing infrastructure

echo "🚀 Multi-Backend Deployment Helper"
echo "====================================="

# Check if we're in the right directory
if [ ! -f "stacks/geo/development/main.tf" ]; then
    echo "❌ Error: Run this script from the root of terraform-infra-python project"
    exit 1
fi

# Get inputs from user
echo ""
echo "📝 Enter details for your new backend:"
echo ""

read -p "Backend name (e.g., 'analytics', 'dataapi', 'websocket'): " backend_name
read -p "Application port (e.g., 3000, 8080, 5001): " app_port  
read -p "GitHub repository name (e.g., 'geoinvestinsights-analytics'): " repo_name
read -p "Backend type/framework (e.g., 'FastAPI', 'Node.js', 'Flask'): " backend_type

# Validate inputs
if [ -z "$backend_name" ] || [ -z "$app_port" ] || [ -z "$repo_name" ] || [ -z "$backend_type" ]; then
    echo "❌ Error: All fields are required"
    exit 1
fi

# Check if port is numeric
if ! [[ "$app_port" =~ ^[0-9]+$ ]]; then
    echo "❌ Error: Port must be numeric"
    exit 1
fi

# Generate the module configuration
cat << EOF >> stacks/geo/development/main.tf

# Backend: $backend_type ($backend_name)
module "geo_${backend_name}_cicd" {
  source        = "../../../modules/cicd"
  environment   = "dev"
  namespace     = "geo"
  backend_name  = "$backend_name"
  application_port = $app_port
  
  github_owner  = "sabeel-it-consulting"
  github_repo   = "$repo_name"
  github_branch = "main"

  # Reuse shared infrastructure
  backend_instance_id = module.shared_infrastructure.backend_instance_id
  codestar_connection_arn = module.shared_infrastructure.codestar_connection_arn

  tags = {
    namespace = "geo"
    backend   = "$backend_name"
  }
}
EOF

echo ""
echo "✅ Successfully added backend configuration!"
echo ""
echo "📋 New Backend Details:"
echo "  Name: $backend_name"
echo "  Port: $app_port"
echo "  Type: $backend_type"
echo "  Repository: $repo_name"
echo "  ECR: geo-dev-$backend_name"
echo "  Pipeline: geo-dev-$backend_name-pipeline"
echo ""
echo "🔧 Next Steps:"
echo "1. Review the configuration in stacks/geo/development/main.tf"
echo "2. Run 'terraform plan' to preview changes"
echo "3. Run 'terraform apply' to deploy the new backend"
echo "4. Ensure your GitHub repository has a proper buildspec.yml"
echo "5. Configure your application to run on port $app_port"
echo ""
echo "📚 For detailed guidance, see MULTI_BACKEND_GUIDE.md"
echo ""

# Show example buildspec.yml content
echo "💡 Example buildspec.yml for your $backend_type backend:"
echo ""
cat << 'EOF'
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...
      - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image...
      - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG

artifacts:
  files:
    - appspec.yml
    - scripts/**/*
EOF