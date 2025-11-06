#!/bin/bash

# This script installs and configures Nginx with Let's Encrypt SSL on the current EC2 instance
# Run this on the EC2 instance to set up HTTPS for the API subdomain

set -e

echo "========================================="
echo "Installing Nginx and Certbot on EC2"
echo "========================================="

# Install Nginx (using amazon-linux-extras for Amazon Linux 2)
echo "Installing Nginx..."
sudo amazon-linux-extras install -y nginx1
sudo systemctl start nginx
sudo systemctl enable nginx
echo "✓ Nginx installed and started"

# Install Certbot (from EPEL repository)
echo "Installing Certbot..."
sudo amazon-linux-extras install -y epel
sudo yum install -y certbot python3-certbot-nginx
echo "✓ Certbot installed"

# Create Nginx configuration for API subdomain (port 5002 - Auth)
echo "Creating Nginx configuration for API (auth)..."
sudo tee /etc/nginx/conf.d/api.conf > /dev/null << 'NGINX_EOF'
server {
    listen 80;
    server_name api.sabeeltech-esg.dev;

    location / {
        proxy_pass http://localhost:5002;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support (if needed)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
NGINX_EOF
echo "✓ Nginx configuration created for API"

# Create Nginx configuration for API1 subdomain (port 8000 - Django)
echo "Creating Nginx configuration for API1 (Django)..."
sudo tee /etc/nginx/conf.d/api1.conf > /dev/null << 'NGINX_EOF'
server {
    listen 80;
    server_name api1.sabeeltech-esg.dev;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support (if needed)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
NGINX_EOF
echo "✓ Nginx configuration created for API1"

# Create Nginx configuration for API2 subdomain (port 5000 - Reports)
echo "Creating Nginx configuration for API2 (Reports)..."
sudo tee /etc/nginx/conf.d/api2.conf > /dev/null << 'NGINX_EOF'
server {
    listen 80;
    server_name api2.sabeeltech-esg.dev;

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support (if needed)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
NGINX_EOF
echo "✓ Nginx configuration created for API2"

# Create Nginx configuration for API3 subdomain (port 5001 - Service)
echo "Creating Nginx configuration for API3 (Service)..."
sudo tee /etc/nginx/conf.d/api3.conf > /dev/null << 'NGINX_EOF'
server {
    listen 80;
    server_name api3.sabeeltech-esg.dev;

    location / {
        proxy_pass http://localhost:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support (if needed)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
NGINX_EOF
echo "✓ Nginx configuration created for API3"

# Test Nginx configuration
echo "Testing Nginx configuration..."
sudo nginx -t
echo "✓ Nginx configuration is valid"

# Reload Nginx
echo "Reloading Nginx..."
sudo systemctl reload nginx
echo "✓ Nginx reloaded"

echo ""
echo "========================================="
echo "Waiting for DNS propagation..."
echo "========================================="
echo "Checking if all domains resolve to this server..."
echo ""

# Get current server's public IP
SERVER_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "Server Elastic IP: $SERVER_IP"

# Check DNS resolution for all domains
DOMAINS=("api.sabeeltech-esg.dev" "api1.sabeeltech-esg.dev" "api2.sabeeltech-esg.dev" "api3.sabeeltech-esg.dev")
ALL_RESOLVED=true

for DOMAIN in "${DOMAINS[@]}"; do
    DNS_IP=$(dig +short $DOMAIN | head -n 1)
    echo "$DOMAIN resolves to: $DNS_IP"
    if [ "$SERVER_IP" != "$DNS_IP" ]; then
        ALL_RESOLVED=false
    fi
done

if [ "$ALL_RESOLVED" = false ]; then
    echo ""
    echo "⚠️  WARNING: Some domains not yet propagated!"
    echo "Expected: $SERVER_IP"
    echo ""
    echo "Please wait 5-10 minutes for DNS propagation, then run:"
    echo "sudo certbot --nginx -d api.sabeeltech-esg.dev -d api1.sabeeltech-esg.dev -d api2.sabeeltech-esg.dev -d api3.sabeeltech-esg.dev --non-interactive --agree-tos --email admin@sabeeltech-esg.dev"
    echo ""
    exit 0
fi

echo "✓ All DNS records correctly point to this server"
echo ""
echo "========================================="
echo "Obtaining SSL Certificate from Let's Encrypt"
echo "========================================="

# Obtain SSL certificate for all domains
sudo certbot --nginx -d api.sabeeltech-esg.dev -d api1.sabeeltech-esg.dev -d api2.sabeeltech-esg.dev -d api3.sabeeltech-esg.dev --non-interactive --agree-tos --email admin@sabeeltech-esg.dev

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "✅ Nginx is running with SSL certificates"
echo "✅ API endpoints are available at:"
echo "   - https://api.sabeeltech-esg.dev (Auth - port 5002)"
echo "   - https://api1.sabeeltech-esg.dev (Django - port 8000)"
echo "   - https://api2.sabeeltech-esg.dev (Reports - port 5000)"
echo "   - https://api3.sabeeltech-esg.dev (Service - port 5001)"
echo "✅ Certificates will auto-renew"
echo ""
echo "Test your APIs:"
echo "curl -I https://api.sabeeltech-esg.dev"
echo "curl -I https://api1.sabeeltech-esg.dev"
echo "curl -I https://api2.sabeeltech-esg.dev"
echo "curl -I https://api3.sabeeltech-esg.dev"
echo ""
