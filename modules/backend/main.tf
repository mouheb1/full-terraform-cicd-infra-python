# Generate SSH key pair automatically
resource "tls_private_key" "backend_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "backend_key" {
  key_name   = "${var.namespace}-${var.environment}-backend-key"
  public_key = tls_private_key.backend_ssh.public_key_openssh

  tags = merge(local.tags, {
    Name = "${var.namespace}-${var.environment}-backend-key"
  })
}

# Save private key locally for SSH access
resource "local_file" "backend_private_key" {
  content         = tls_private_key.backend_ssh.private_key_pem
  filename        = "${path.root}/${var.namespace}-${var.environment}-backend-key.pem"
  file_permission = "0400"
}

# Security Group for EC2 instance
resource "aws_security_group" "backend_sg" {
  name_prefix = "${var.namespace}-${var.environment}-backend-"
  vpc_id      = var.vpc_id

  # Allow HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS traffic
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow application port (3000 for NestJS)
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.namespace}-${var.environment}-backend-sg"
  })
}

# IAM role for EC2 instance
resource "aws_iam_role" "backend_role" {
  name = "${var.namespace}-${var.environment}-backend-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.tags, {
    Name = "${var.namespace}-${var.environment}-backend-role"
  })
}

# IAM policy for CodeDeploy agent
resource "aws_iam_role_policy" "backend_codedeploy_policy" {
  name = "${var.namespace}-${var.environment}-backend-codedeploy-policy"
  role = aws_iam_role.backend_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.namespace}-${var.environment}-*",
          "arn:aws:s3:::${var.namespace}-${var.environment}-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

# IAM instance profile
resource "aws_iam_instance_profile" "backend_profile" {
  name = "${var.namespace}-${var.environment}-backend-profile"
  role = aws_iam_role.backend_role.name

  tags = merge(local.tags, {
    Name = "${var.namespace}-${var.environment}-backend-profile"
  })
}

# Attach S3 access policy if provided
resource "aws_iam_role_policy_attachment" "s3_access" {
  # count      = var.s3_access_policy_arn != "" ? 1 : 0
  policy_arn = var.s3_access_policy_arn
  role       = aws_iam_role.backend_role.name
}

# User data script for EC2 instance
locals {
  user_data = templatefile("${path.module}/user_data.sh", {
    region                        = data.aws_region.current.id
    namespace                     = var.namespace
    environment                   = var.environment
    node_env                      = var.node_env
    db_host                       = split(":", var.db_host)[0]
    db_port                       = var.db_port
    db_name                       = var.db_name
    db_user                       = var.db_user
    db_password                   = var.db_password
    ssh_public_key                = tls_private_key.backend_ssh.public_key_openssh
    jwt_private_key               = var.jwt_private_key
    jwt_public_key                = var.jwt_public_key
    jwt_refresh_token_private_key = var.jwt_refresh_token_private_key
  })
}

# EC2 instance
resource "aws_instance" "backend" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.backend_key.key_name
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  subnet_id              = var.public_subnet_ids[0]
  iam_instance_profile   = aws_iam_instance_profile.backend_profile.name
  user_data_base64       = base64encode(local.user_data)

  root_block_device {
    volume_type = "gp3"
    volume_size = 8     # Reduced from 20GB to 8GB (minimum for Amazon Linux)
    encrypted   = false # Remove encryption to save costs on free tier
  }

  tags = merge(local.tags, {
    Name = "${var.namespace}-${var.environment}-backend"
    App  = "backend"
  })
}
