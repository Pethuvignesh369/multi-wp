# EC2 WordPress Multi-Site Deployment Guide

## Prerequisites
- EC2 instance running Ubuntu 20.04 or 22.04
- Root or sudo access
- Domain names pointing to your EC2 instance IP
- Security group allowing ports 22 (SSH), 80 (HTTP), 443 (HTTPS)

## Installation Steps

### 1. Connect to EC2 Instance
```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

### 2. Upload Deployment Files
```bash
# From your local machine
scp -i your-key.pem -r * ubuntu@your-ec2-ip:~/deployment/
```

### 3. Run Deployment Script
```bash
cd ~/deployment
chmod +x deploy.sh
sudo ./deploy.sh
```

### 4. Configure Databases
```bash
# Edit setup-databases.sql and change passwords
nano setup-databases.sql

# Run SQL script
sudo mysql -u root -p < setup-databases.sql
```

### 5. Download WordPress
```bash
# Site 1 (PHP 8.1)
cd /var/www/site1
sudo wget https://wordpress.org/latest.tar.gz
sudo tar -xzf latest.tar.gz --strip-components=1
sudo rm latest.tar.gz

# Site 2 (PHP 8.4)
cd /var/www/site2
sudo wget https://wordpress.org/latest.tar.gz
sudo tar -xzf latest.tar.gz --strip-components=1
sudo rm latest.tar.gz

# Set permissions
sudo chown -R www-data:www-data /var/www/site1
sudo chown -R www-data:www-data /var/www/site2
```

### 6. Configure WordPress

#### Site 1
```bash
cd /var/www/site1
sudo cp wp-config-sample.php wp-config.php
sudo nano wp-config.php
```

Update database settings:
```php
define('DB_NAME', 'wordpress_site1');
define('DB_USER', 'wp_site1');
define('DB_PASSWORD', 'CHANGE_THIS_PASSWORD_1');
define('DB_HOST', 'localhost');
```

#### Site 2
```bash
cd /var/www/site2
sudo cp wp-config-sample.php wp-config.php
sudo nano wp-config.php
```

Update database settings:
```php
define('DB_NAME', 'wordpress_site2');
define('DB_USER', 'wp_site2');
define('DB_PASSWORD', 'CHANGE_THIS_PASSWORD_2');
define('DB_HOST', 'localhost');
```

### 7. Update NGINX Site Configurations
```bash
# Edit site1.conf
sudo nano /etc/nginx/sites-available/site1
# Change: server_name site1.example.com; to your actual domain

# Edit site2.conf
sudo nano /etc/nginx/sites-available/site2
# Change: server_name site2.example.com; to your actual domain

# Test and reload NGINX
sudo nginx -t
sudo systemctl reload nginx
```

### 8. Configure PHPMyAdmin (Optional)
```bash
# Create symlink to PHPMyAdmin
sudo ln -s /usr/share/phpmyadmin /var/www/phpmyadmin

# Add NGINX config for PHPMyAdmin
sudo nano /etc/nginx/sites-available/phpmyadmin
```

Add this configuration:
```nginx
server {
    listen 80;
    server_name phpmyadmin.example.com;
    root /var/www/phpmyadmin;
    index index.php;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }
}
```

Enable and reload:
```bash
sudo ln -s /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 9. Setup SSL with Let's Encrypt (Recommended)
```bash
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d site1.example.com
sudo certbot --nginx -d site2.example.com
```

### 10. Configure FTP/SFTP Access
SFTP is already enabled via SSH. For FTP with SSH keys:

```bash
# Create FTP users
sudo adduser ftpuser1
sudo adduser ftpuser2

# Add to www-data group
sudo usermod -a -G www-data ftpuser1
sudo usermod -a -G www-data ftpuser2

# Set home directories
sudo usermod -d /var/www/site1 ftpuser1
sudo usermod -d /var/www/site2 ftpuser2

# Copy SSH keys
sudo mkdir -p /home/ftpuser1/.ssh
sudo cp ~/.ssh/authorized_keys /home/ftpuser1/.ssh/
sudo chown -R ftpuser1:ftpuser1 /home/ftpuser1/.ssh
sudo chmod 700 /home/ftpuser1/.ssh
sudo chmod 600 /home/ftpuser1/.ssh/authorized_keys
```

## Security Checklist
- [ ] Change all default passwords
- [ ] Configure firewall (ufw)
- [ ] Enable SSL certificates
- [ ] Disable root SSH login
- [ ] Configure automatic security updates
- [ ] Set up regular backups
- [ ] Restrict PHPMyAdmin access by IP

## Firewall Configuration
```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## Monitoring and Maintenance
```bash
# Check service status
sudo systemctl status nginx
sudo systemctl status php8.1-fpm
sudo systemctl status php8.4-fpm
sudo systemctl status mariadb

# View logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/site1-access.log
```

## Troubleshooting
- If sites don't load, check NGINX error logs
- Verify PHP-FPM sockets are running
- Ensure database credentials are correct
- Check file permissions (www-data:www-data)
- Verify security group rules in AWS console
