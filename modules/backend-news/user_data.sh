#!/bin/bash
yum update -y

# Install Python 3.11 and pip
yum install -y python3 python3-pip

# Wait for EBS volume to be attached
echo "Waiting for EBS volume /dev/xvdf to be attached..."
while [ ! -e /dev/xvdf ]; do
  sleep 5
done

# Format and mount EBS volume for Docker data
echo "Formatting and mounting EBS volume for Docker..."
if ! blkid /dev/xvdf | grep -q ext4; then
  mkfs -t ext4 /dev/xvdf
fi

# Create mount point
mkdir -p /var/lib/docker

# Mount the volume
mount /dev/xvdf /var/lib/docker

# Add to fstab for persistent mount after reboot
DEVICE_UUID=$(blkid -s UUID -o value /dev/xvdf)
echo "UUID=$DEVICE_UUID /var/lib/docker ext4 defaults,nofail 0 2" >> /etc/fstab

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

# Create directories for NEWS backend projects
%{ for project in backend_projects }
mkdir -p ${project.path}
chown ec2-user:ec2-user ${project.path}
%{ endfor }

# Create environment files for NEWS backend projects
%{ for project in backend_projects }
# Generic environment file for ${project.name}
ENV_CONTENT=$(cat << 'ENV_EOF'
# Flask Environment
FLASK_ENV=${python_env}
FLASK_DEBUG=false
DEBUG=false
HOST=0.0.0.0

# Database Configuration
DATABASE_URL=postgresql://${db_user}:${db_password}@${db_host}:${db_port}/${db_name}
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_password}

# Infrastructure Variables
NAMESPACE=${namespace}
ENVIRONMENT=${environment}
ENV_EOF
)

echo "$ENV_CONTENT" > ${project.path}/.env
chown ec2-user:ec2-user ${project.path}/.env
echo "Created .env file for ${project.name} at ${project.path}/.env"
%{ endfor }

# Install Nginx (using amazon-linux-extras for Amazon Linux 2)
amazon-linux-extras install -y nginx1
systemctl start nginx
systemctl enable nginx

# Install Certbot for Let's Encrypt SSL certificates (from EPEL repository)
amazon-linux-extras install -y epel
yum install -y certbot python3-certbot-nginx

# Create Nginx configuration for api subdomain (newsapp-backend - Port 5000)
cat > /etc/nginx/conf.d/api.conf << 'NGINX_EOF'
server {
    listen 80;
    server_name api.newsaidemo.dev;

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_EOF

# Create Nginx configuration for api1 subdomain (newsapp-backend REST API - Port 5000)
cat > /etc/nginx/conf.d/api1.conf << 'NGINX_EOF'
server {
    listen 80;
    server_name api1.newsaidemo.dev;

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_EOF

# Test and reload Nginx configuration
nginx -t && systemctl reload nginx

# Create a script to obtain SSL certificate after DNS propagation
cat > /usr/local/bin/obtain-ssl-cert.sh << 'SSL_SCRIPT_EOF'
#!/bin/bash
LOG_FILE="/var/log/ssl-cert-setup.log"
MAX_RETRIES=30
RETRY_DELAY=60
DOMAINS=("api.newsaidemo.dev" "api1.newsaidemo.dev")

echo "$(date): Starting SSL certificate setup for NEWS stack" >> $LOG_FILE
ELASTIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "$(date): Instance Elastic IP: $ELASTIC_IP" >> $LOG_FILE

for i in $(seq 1 $MAX_RETRIES); do
    echo "$(date): Checking DNS resolution (attempt $i/$MAX_RETRIES)..." >> $LOG_FILE
    ALL_RESOLVED=true
    for DOMAIN in "$${DOMAINS[@]}"; do
        DNS_IP=$(dig +short $DOMAIN | head -n 1)
        if [ "$DNS_IP" != "$ELASTIC_IP" ]; then
            echo "$(date): $DOMAIN not propagated. Expected: $ELASTIC_IP, Got: $DNS_IP" >> $LOG_FILE
            ALL_RESOLVED=false
            break
        fi
    done

    if [ "$ALL_RESOLVED" = true ]; then
        echo "$(date): All DNS records resolved correctly" >> $LOG_FILE
        systemctl stop nginx

        echo "$(date): Obtaining SSL certificates..." >> $LOG_FILE
        certbot certonly --standalone --preferred-challenges http \
            -d api.newsaidemo.dev \
            -d api1.newsaidemo.dev \
            --non-interactive \
            --agree-tos \
            --email admin@newsaidemo.dev >> $LOG_FILE 2>&1

        if [ $? -eq 0 ]; then
            echo "$(date): SSL certificates obtained successfully!" >> $LOG_FILE

            cat > /etc/nginx/conf.d/api.conf << 'NGINX_HTTPS_EOF'
server {
    listen 80;
    server_name api.newsaidemo.dev;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.newsaidemo.dev;

    ssl_certificate /etc/letsencrypt/live/api.newsaidemo.dev/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.newsaidemo.dev/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
NGINX_HTTPS_EOF

            cat > /etc/nginx/conf.d/api1.conf << 'NGINX_HTTPS_EOF'
server {
    listen 80;
    server_name api1.newsaidemo.dev;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api1.newsaidemo.dev;

    ssl_certificate /etc/letsencrypt/live/api.newsaidemo.dev/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.newsaidemo.dev/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
NGINX_HTTPS_EOF

            nginx -t && systemctl start nginx
            echo "$(date): Nginx restarted with HTTPS configuration" >> $LOG_FILE
            systemctl disable ssl-cert-setup.service
            exit 0
        else
            echo "$(date): Failed to obtain SSL certificates" >> $LOG_FILE
            systemctl start nginx
        fi
    fi
    sleep $RETRY_DELAY
done

echo "$(date): Failed to obtain SSL after $MAX_RETRIES attempts" >> $LOG_FILE
systemctl start nginx
exit 1
SSL_SCRIPT_EOF

chmod +x /usr/local/bin/obtain-ssl-cert.sh

cat > /etc/systemd/system/ssl-cert-setup.service << 'SERVICE_EOF'
[Unit]
Description=Obtain Let's Encrypt SSL Certificate for NEWS API
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/obtain-ssl-cert.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE_EOF

systemctl daemon-reload
systemctl enable ssl-cert-setup.service
systemctl start ssl-cert-setup.service &
systemctl enable certbot-renew.timer

# Docker cleanup script
cat > /usr/local/bin/docker-cleanup.sh << 'DOCKER_CLEANUP_EOF'
#!/bin/bash
LOG_FILE="/var/log/docker-cleanup.log"
echo "$(date): Starting Docker cleanup..." >> $LOG_FILE
docker image prune -a -f --filter "until=1h" >> $LOG_FILE 2>&1
docker system prune -f >> $LOG_FILE 2>&1
echo "$(date): Docker cleanup completed" >> $LOG_FILE
DOCKER_CLEANUP_EOF

chmod +x /usr/local/bin/docker-cleanup.sh
echo "0 * * * * /usr/local/bin/docker-cleanup.sh" | crontab -
systemctl enable crond
systemctl start crond

echo "NEWS stack EC2 setup completed" > /var/log/user-data.log
