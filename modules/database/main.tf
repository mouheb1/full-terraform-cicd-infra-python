

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

# DB Subnet Group (required for RDS)
resource "aws_db_subnet_group" "database" {
  name       = "${var.namespace}-${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(local.tags, {
    Name = "${var.namespace}-${var.environment}-db-subnet-group"
  })
}


# Security Group for RDS
resource "aws_security_group" "database" {
  name_prefix = "${var.namespace}-${var.environment}-db-"
  vpc_id      = var.vpc_id

  # Allow PostgreSQL access from EC2 instances
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.backend_security_group_id]
  }

  # No outbound rules needed for RDS
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.namespace}-${var.environment}-database-sg"
  })
}


# RDS Instance - Optimized for lowest cost
resource "aws_db_instance" "database" {
  # Basic Configuration
  identifier     = "${var.namespace}-${var.environment}-db"
  db_name        = replace("${var.namespace}_${var.environment}", "-", "_")
  engine         = "postgres"
  engine_version = "17.4"        # Use stable version, not latest
  instance_class = "db.t3.small" # Smallest instance

  # Storage - Minimum for cost optimization
  allocated_storage = 20 # Minimum for PostgreSQL
  # max_allocated_storage = 100   # Auto-scaling limit
  storage_type      = "gp3" # General Purpose SSD (cheaper than gp3)
  storage_encrypted = false # Encryption costs extra

  # Credentials
  username = var.db_username
  password = var.db_password

  # Networking
  db_subnet_group_name   = aws_db_subnet_group.database.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false # Keep private for security

  # Backup & Maintenance - Minimize for cost
  backup_retention_period = 0 # Minimum backup retention
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"
  skip_final_snapshot     = true  # Skip final snapshot for dev
  deletion_protection     = false # Allow easy deletion for dev

  # Performance & Monitoring - Minimize for cost
  monitoring_interval      = 0 # Disable enhanced monitoring
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"

  # Parameter Group
  parameter_group_name = "default.postgres17"

  tags = merge(local.tags, {
    Name = "${var.namespace}-${var.environment}-database"
  })
}

resource "aws_db_parameter_group" "database_params" {
  name        = "${var.namespace}-${var.environment}-db-params"
  family      = "postgres17"
  description = "Custom parameter group for ${var.namespace}-${var.environment} PostgreSQL"

  parameter {
    name         = "max_connections"
    value        = "100"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot" # rds.force_ssl is a static parameter
  }

  tags = merge(local.tags, {
    Name = "${var.namespace}-${var.environment}-db-parameter-group"
  })
}
