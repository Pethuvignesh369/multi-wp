#!/bin/bash
# EC2 WordPress Multi-Site Deployment Script
# Run as root or with sudo

set -e

echo "=== Starting EC2 WordPress Multi-Site Setup ==="

# Update system
echo "Updating system packages..."
apt-get update && apt-get upgrade -y

# Install NGINX
echo "Installing NGINX..."
apt-get install -y nginx

# Install PHP 8.1 and PHP 8.4
echo "Adding PHP repository..."
apt-get install -y software-properties-common
add-apt-repository -y ppa:ondrej/php
apt-get update

echo "Installing PHP 8.1..."
apt-get install -y php8.1-fpm php8.1-mysql php8.1-curl php8.1-gd php8.1-mbstring php8.1-xml php8.1-xmlrpc php8.1-soap php8.1-intl php8.1-zip

echo "Installing PHP 8.4..."
apt-get install -y php8.4-fpm php8.4-mysql php8.4-curl php8.4-gd php8.4-mbstring php8.4-xml php8.4-xmlrpc php8.4-soap php8.4-intl php8.4-zip

# Install MariaDB
echo "Installing MariaDB..."
apt-get install -y mariadb-server mariadb-client

# Secure MariaDB installation
echo "Securing MariaDB..."
mysql_secure_installation

# Install PHPMyAdmin
echo "Installing PHPMyAdmin..."
apt-get install -y phpmyadmin

# Create directories for WordPress sites
echo "Creating WordPress directories..."
mkdir -p /var/www/site1
mkdir -p /var/www/site2
mkdir -p /var/www/phpmyadmin

# Set permissions
chown -R www-data:www-data /var/www/site1
chown -R www-data:www-data /var/www/site2
chmod -R 755 /var/www/site1
chmod -R 755 /var/www/site2

# Copy NGINX configurations
echo "Configuring NGINX..."
cp nginx/nginx.conf /etc/nginx/nginx.conf
cp nginx/site1.conf /etc/nginx/sites-available/site1
cp nginx/site2.conf /etc/nginx/sites-available/site2

# Enable sites
ln -sf /etc/nginx/sites-available/site1 /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/site2 /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test NGINX configuration
nginx -t

# Restart services
echo "Restarting services..."
systemctl restart php8.1-fpm
systemctl restart php8.4-fpm
systemctl restart nginx
systemctl restart mariadb

# Enable services on boot
systemctl enable nginx
systemctl enable php8.1-fpm
systemctl enable php8.4-fpm
systemctl enable mariadb

echo "=== Setup Complete ==="
echo "Next steps:"
echo "1. Run: mysql -u root -p < setup-databases.sql"
echo "2. Download WordPress to /var/www/site1 and /var/www/site2"
echo "3. Configure wp-config.php for each site"
echo "4. Update your domain DNS to point to this EC2 instance"
