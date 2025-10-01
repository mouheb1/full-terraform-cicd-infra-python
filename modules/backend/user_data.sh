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

# Create environment file for Docker containers
# Create directories and environment files for each backend project
%{ for project in backend_projects }
mkdir -p ${project.path}
chown ec2-user:ec2-user ${project.path}
%{ endfor }

# Create service-specific environment files
%{ for project in backend_projects }
%{ if project.name == "geoinvestinsights-backend" }
# Django Main Backend Environment
ENV_CONTENT=$(cat << 'ENV_EOF'
# Django Main Backend (Port 8000)
DJANGO_ENV=${python_env}
DEBUG=false
PORT=8000
SECRET_KEY=${django_secret_key}
ALLOWED_HOSTS=*

# Common Database Configuration
DATABASE_URL=postgresql://${db_user}:${db_password}@${db_host}:${db_port}/${db_name}
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_password}

# Infrastructure Variables
NAMESPACE=${namespace}
ENVIRONMENT=${environment}

# Google Earth Engine (for backends that need it)
GOOGLE_APPLICATION_CREDENTIALS=/opt/app/service-account-key.json
ENV_EOF
)
%{ endif }

%{ if project.name == "geoinvestinsights-authback" }
# Auth Backend Environment
ENV_CONTENT=$(cat << 'ENV_EOF'
# Auth Backend (Port 5002)
FLASK_ENV=${python_env}
FLASK_DEBUG=false
PORT=5002
HOST=0.0.0.0
JWT_SECRET_KEY=${jwt_secret_key}

# Common Database Configuration
DATABASE_URL=postgresql://${db_user}:${db_password}@${db_host}:${db_port}/${db_name}
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_password}

# Infrastructure Variables
NAMESPACE=${namespace}
ENVIRONMENT=${environment}

# Google Earth Engine (for backends that need it)
GOOGLE_APPLICATION_CREDENTIALS=/opt/app/service-account-key.json
ENV_EOF
)
%{ endif }

%{ if project.name == "geoinvestinsights-secondback" }
# Second Backend Environment
ENV_CONTENT=$(cat << 'ENV_EOF'
# Second Backend - Report Generation (Port 5000)
FLASK_ENV=${python_env}
FLASK_DEBUG=false
PORT=5000
HOST=0.0.0.0

# Common Database Configuration
DATABASE_URL=postgresql://${db_user}:${db_password}@${db_host}:${db_port}/${db_name}
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_password}

# Infrastructure Variables
NAMESPACE=${namespace}
ENVIRONMENT=${environment}

# Google Earth Engine (for backends that need it)
GOOGLE_APPLICATION_CREDENTIALS=/opt/app/service-account-key.json
ENV_EOF
)
%{ endif }

%{ if project.name == "geoinvestinsights-thirdback" }
# Third Backend Environment
ENV_CONTENT=$(cat << 'ENV_EOF'
# Third Backend - Agricultural Analysis (Port 5001)
FLASK_ENV=${python_env}
FLASK_DEBUG=false
PORT=5001
HOST=0.0.0.0

# Common Database Configuration
DATABASE_URL=postgresql://${db_user}:${db_password}@${db_host}:${db_port}/${db_name}
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_password}

# Infrastructure Variables
NAMESPACE=${namespace}
ENVIRONMENT=${environment}

# Google Earth Engine (for backends that need it)
GOOGLE_APPLICATION_CREDENTIALS=/opt/app/service-account-key.json
ENV_EOF
)
%{ endif }

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

# Create Nginx configuration for API subdomain (reverse proxy to port 5002)
cat > /etc/nginx/conf.d/api.conf << 'NGINX_EOF'
server {
    listen 80;
    server_name api.sabeeltech-esg.dev;

    location / {
        proxy_pass http://localhost:5002;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_EOF

# Create Nginx configuration for API1 subdomain (reverse proxy to port 8000 - Django)
cat > /etc/nginx/conf.d/api1.conf << 'NGINX_EOF'
server {
    listen 80;
    server_name api1.sabeeltech-esg.dev;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_EOF

# Create Nginx configuration for API2 subdomain (reverse proxy to port 5000 - Reports)
cat > /etc/nginx/conf.d/api2.conf << 'NGINX_EOF'
server {
    listen 80;
    server_name api2.sabeeltech-esg.dev;

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_EOF

# Create Nginx configuration for API3 subdomain (reverse proxy to port 5001 - Service)
cat > /etc/nginx/conf.d/api3.conf << 'NGINX_EOF'
server {
    listen 80;
    server_name api3.sabeeltech-esg.dev;

    location / {
        proxy_pass http://localhost:5001;
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
# Script to obtain Let's Encrypt SSL certificate after DNS propagation

LOG_FILE="/var/log/ssl-cert-setup.log"
MAX_RETRIES=30
RETRY_DELAY=60
DOMAINS=("api.sabeeltech-esg.dev" "api1.sabeeltech-esg.dev" "api2.sabeeltech-esg.dev" "api3.sabeeltech-esg.dev")

echo "$(date): Starting SSL certificate setup for all domains" >> $LOG_FILE

# Get the Elastic IP of this instance
ELASTIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "$(date): Instance Elastic IP: $ELASTIC_IP" >> $LOG_FILE

# Wait for DNS to propagate for all domains
for i in $(seq 1 $MAX_RETRIES); do
    echo "$(date): Checking DNS resolution (attempt $i/$MAX_RETRIES)..." >> $LOG_FILE

    ALL_RESOLVED=true
    for DOMAIN in "$${DOMAINS[@]}"; do
        DNS_IP=$(dig +short $DOMAIN | head -n 1)
        if [ "$DNS_IP" != "$ELASTIC_IP" ]; then
            echo "$(date): $DOMAIN not yet propagated. Expected: $ELASTIC_IP, Got: $DNS_IP" >> $LOG_FILE
            ALL_RESOLVED=false
            break
        fi
    done

    if [ "$ALL_RESOLVED" = true ]; then
        echo "$(date): All DNS records resolved correctly" >> $LOG_FILE

        # Stop nginx temporarily to allow certbot standalone mode
        systemctl stop nginx

        # Obtain SSL certificate for all domains
        echo "$(date): Obtaining SSL certificates..." >> $LOG_FILE
        certbot certonly --standalone --preferred-challenges http \
            -d api.sabeeltech-esg.dev \
            -d api1.sabeeltech-esg.dev \
            -d api2.sabeeltech-esg.dev \
            -d api3.sabeeltech-esg.dev \
            --non-interactive \
            --agree-tos \
            --email admin@sabeeltech-esg.dev >> $LOG_FILE 2>&1

        if [ $? -eq 0 ]; then
            echo "$(date): SSL certificates obtained successfully!" >> $LOG_FILE

            # Update Nginx configuration to use HTTPS for api (port 5002)
            cat > /etc/nginx/conf.d/api.conf << 'NGINX_HTTPS_EOF'
server {
    listen 80;
    server_name api.sabeeltech-esg.dev;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.sabeeltech-esg.dev;

    ssl_certificate /etc/letsencrypt/live/api.sabeeltech-esg.dev/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.sabeeltech-esg.dev/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://localhost:5002;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
NGINX_HTTPS_EOF

            # Update Nginx configuration to use HTTPS for api1 (port 8000 - Django)
            cat > /etc/nginx/conf.d/api1.conf << 'NGINX_HTTPS_EOF'
server {
    listen 80;
    server_name api1.sabeeltech-esg.dev;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api1.sabeeltech-esg.dev;

    ssl_certificate /etc/letsencrypt/live/api.sabeeltech-esg.dev/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.sabeeltech-esg.dev/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
NGINX_HTTPS_EOF

            # Update Nginx configuration to use HTTPS for api2 (port 5000 - Reports)
            cat > /etc/nginx/conf.d/api2.conf << 'NGINX_HTTPS_EOF'
server {
    listen 80;
    server_name api2.sabeeltech-esg.dev;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api2.sabeeltech-esg.dev;

    ssl_certificate /etc/letsencrypt/live/api.sabeeltech-esg.dev/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.sabeeltech-esg.dev/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
NGINX_HTTPS_EOF

            # Update Nginx configuration to use HTTPS for api3 (port 5001 - Service)
            cat > /etc/nginx/conf.d/api3.conf << 'NGINX_HTTPS_EOF'
server {
    listen 80;
    server_name api3.sabeeltech-esg.dev;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api3.sabeeltech-esg.dev;

    ssl_certificate /etc/letsencrypt/live/api.sabeeltech-esg.dev/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.sabeeltech-esg.dev/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://localhost:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
NGINX_HTTPS_EOF

            # Test and start nginx
            nginx -t && systemctl start nginx
            echo "$(date): Nginx restarted with HTTPS configuration for all domains" >> $LOG_FILE

            # Disable this service so it doesn't run again
            systemctl disable ssl-cert-setup.service

            exit 0
        else
            echo "$(date): Failed to obtain SSL certificates" >> $LOG_FILE
            systemctl start nginx
        fi
    fi

    sleep $RETRY_DELAY
done

echo "$(date): Failed to obtain SSL certificates after $MAX_RETRIES attempts" >> $LOG_FILE
systemctl start nginx
exit 1
SSL_SCRIPT_EOF

chmod +x /usr/local/bin/obtain-ssl-cert.sh

# Create systemd service to run the SSL certificate setup script
cat > /etc/systemd/system/ssl-cert-setup.service << 'SERVICE_EOF'
[Unit]
Description=Obtain Let's Encrypt SSL Certificate for API
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/obtain-ssl-cert.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable ssl-cert-setup.service
systemctl start ssl-cert-setup.service &

# Setup automatic certificate renewal
systemctl enable certbot-renew.timer

echo "EC2 setup completed with Nginx and SSL certificate automation" > /var/log/user-data.log