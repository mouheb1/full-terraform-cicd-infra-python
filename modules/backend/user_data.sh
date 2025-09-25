#!/bin/bash
yum update -y

# Install Python 3.11 and pip
yum install -y python3 python3-pip

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install CodeDeploy agent
yum install -y ruby wget
cd /home/ec2-user
wget https://aws-codedeploy-${region}.s3.${region}.amazonaws.com/latest/install
chmod +x ./install
./install auto

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Create application directory
mkdir -p /opt/app
chown ec2-user:ec2-user /opt/app

# Create log directory for CodeDeploy
mkdir -p /var/log/codedeploy-agent
chown ec2-user:ec2-user /var/log/codedeploy-agent

# Start CodeDeploy agent
service codedeploy-agent start
chkconfig codedeploy-agent on

# Setup SSH key for ec2-user (add the generated public key)
mkdir -p /home/ec2-user/.ssh
echo "${ssh_public_key}" >> /home/ec2-user/.ssh/authorized_keys
chmod 700 /home/ec2-user/.ssh
chmod 600 /home/ec2-user/.ssh/authorized_keys
chown -R ec2-user:ec2-user /home/ec2-user/.ssh

# Create environment file for Docker container
cat > /opt/app/.env << EOF
DJANGO_ENV=${python_env}
DEBUG=false
PORT=8000
NAMESPACE=${namespace}
ENVIRONMENT=${environment}
DATABASE_URL=postgresql://${db_user}:${db_password}@${db_host}:${db_port}/${db_name}
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_password}
SECRET_KEY=${django_secret_key}
ALLOWED_HOSTS=*
EOF

echo "EC2 setup completed" > /var/log/user-data.log