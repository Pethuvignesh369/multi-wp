# Docker WordPress Multi-Site Installation Guide

Complete step-by-step guide for deploying WordPress multi-site setup using Docker on EC2, KymaCloud, or any Linux server.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Quick Installation](#quick-installation)
3. [Manual Installation](#manual-installation)
4. [WordPress Configuration](#wordpress-configuration)
5. [SSL Setup](#ssl-setup)
6. [SFTP Access](#sftp-access)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Server Requirements
- Linux server (Ubuntu 20.04+, Amazon Linux 2, or Debian)
- Minimum 4GB RAM (t2.medium or equivalent)
- 20GB+ storage
- Root or sudo access

### Network Requirements
- Open ports: 22 (SSH), 80 (HTTP), 443 (HTTPS), 2221 (SFTP), 2222 (SFTP)
- Optional: 8080, 8081 (PHPMyAdmin - restrict by IP in production)

### Domain Setup
- Two domain names or subdomains pointing to your server IP
- Example: site1.example.com, site2.example.com

---

## Quick Installation

### Option 1: Automated Script (Recommended)

```bash
# 1. Connect to your server
ssh -i your-key.pem ubuntu@your-server-ip

# 2. Clone or upload the repository
git clone <your-repo-url>
cd <repo-directory>

# 3. Make script executable
chmod +x deploy-docker.sh

# 4. Run deployment script
sudo ./deploy-docker.sh
```

The script will:
- Install Docker and Docker Compose
- Generate secure passwords
- Create SSH keys for SFTP
- Pull Docker images
- Start all services
- Display access information

**That's it!** Skip to [WordPress Configuration](#wordpress-configuration)

---

## Manual Installation

### Step 1: Install Docker

#### Ubuntu/Debian
```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

#### Amazon Linux 2
```bash
# Update system
sudo yum update -y

# Install Docker
sudo yum install -y docker

# Start Docker
sudo service docker start
sudo systemctl enable docker

# Add user to docker group
sudo usermod -a -G docker ec2-user
```

### Step 2: Install Docker Compose

```bash
# Download Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

### Step 3: Setup Project Files

```bash
# Create project directory
mkdir -p ~/wordpress-multisite
cd ~/wordpress-multisite

# Upload all project files here
# Or clone from git repository
```

### Step 4: Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit with your passwords
nano .env
```

Update these values in `.env`:
```env
MYSQL_ROOT_PASSWORD=your_secure_mysql_password_here
MARIADB_ROOT_PASSWORD=your_secure_mariadb_password_here
WP_SITE1_DB_PASSWORD=your_site1_password_here
WP_SITE2_DB_PASSWORD=your_site2_password_here
```

**Security Tip:** Generate strong passwords:
```bash
openssl rand -base64 32
```

### Step 5: Update Domain Names

Edit NGINX configurations with your actual domains:

```bash
# Site 1
nano nginx/docker-site1.conf
# Change: server_name site1.example.com localhost;

# Site 2
nano nginx/docker-site2.conf
# Change: server_name site2.example.com;
```

### Step 6: Create Directories

```bash
mkdir -p logs/nginx
mkdir -p ssh-keys/site1
mkdir -p ssh-keys/site2
mkdir -p backups
```

### Step 7: Generate SSH Keys for SFTP

```bash
# Site 1
ssh-keygen -t rsa -b 4096 -f ssh-keys/site1/id_rsa -N ""

# Site 2
ssh-keygen -t rsa -b 4096 -f ssh-keys/site2/id_rsa -N ""

# Set permissions
chmod 600 ssh-keys/*/id_rsa
chmod 644 ssh-keys/*/id_rsa.pub
```

### Step 8: Configure Firewall

#### Using UFW (Ubuntu/Debian)
```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 2221/tcp
sudo ufw allow 2222/tcp
sudo ufw enable
sudo ufw status
```

#### AWS Security Group
Add inbound rules:
- SSH: Port 22, Source: Your IP
- HTTP: Port 80, Source: 0.0.0.0/0
- HTTPS: Port 443, Source: 0.0.0.0/0
- SFTP Site 1: Port 2221, Source: Your IP
- SFTP Site 2: Port 2222, Source: Your IP
- PHPMyAdmin: Ports 8080, 8081, Source: Your IP (optional)

### Step 9: Start Services

```bash
# Pull images
docker-compose pull

# Start in background
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

---

## WordPress Configuration

### Site 1 Setup (PHP 8.1 + MySQL)

1. Open browser: `http://your-server-ip` or `http://site1.example.com`
2. Select language
3. Click "Let's go!"
4. Enter database details (already configured via environment variables)
5. Click "Run the installation"
6. Fill in site information:
   - **Site Title:** Your Site 1 Name
   - **Username:** admin (or your preferred username)
   - **Password:** Use a strong password
   - **Email:** your@email.com
7. Click "Install WordPress"
8. Login and start customizing

### Site 2 Setup (PHP 8.4 + MariaDB)

1. Open browser: `http://site2.example.com`
2. Follow same steps as Site 1
3. Use different admin credentials for security

### Verify Database Connections

```bash
# Check Site 1 database
docker-compose exec mysql mysql -u wp_site1 -p wordpress_site1
# Enter password from .env: WP_SITE1_DB_PASSWORD

# Check Site 2 database
docker-compose exec mariadb mysql -u wp_site2 -p wordpress_site2
# Enter password from .env: WP_SITE2_DB_PASSWORD
```

---

## SSL Setup

### Using Let's Encrypt (Recommended)

#### Install Certbot
```bash
# Ubuntu/Debian
sudo apt-get install -y certbot

# Amazon Linux 2
sudo yum install -y certbot
```

#### Generate Certificates
```bash
# Stop NGINX temporarily
docker-compose stop nginx

# Generate certificates
sudo certbot certonly --standalone -d site1.example.com
sudo certbot certonly --standalone -d site2.example.com

# Certificates will be in: /etc/letsencrypt/live/
```

#### Update Docker Compose
Add to `docker-compose.yml` under nginx volumes:
```yaml
- /etc/letsencrypt:/etc/letsencrypt:ro
```

#### Update NGINX Configs
Add to each site config:
```nginx
server {
    listen 443 ssl http2;
    server_name site1.example.com;
    
    ssl_certificate /etc/letsencrypt/live/site1.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/site1.example.com/privkey.pem;
    
    # ... rest of config
}

server {
    listen 80;
    server_name site1.example.com;
    return 301 https://$server_name$request_uri;
}
```

#### Restart NGINX
```bash
docker-compose restart nginx
```

#### Auto-Renewal
```bash
# Test renewal
sudo certbot renew --dry-run

# Add to crontab
sudo crontab -e
# Add: 0 3 * * * certbot renew --quiet && docker-compose restart nginx
```

---

## SFTP Access

### Using Command Line

#### Site 1
```bash
sftp -P 2221 -i ssh-keys/site1/id_rsa ftpuser1@your-server-ip
```

#### Site 2
```bash
sftp -P 2222 -i ssh-keys/site2/id_rsa ftpuser2@your-server-ip
```

### Using FileZilla

1. Open FileZilla
2. Go to Edit → Settings → SFTP
3. Click "Add key file" and select `ssh-keys/site1/id_rsa`
4. Create new site:
   - **Protocol:** SFTP
   - **Host:** your-server-ip
   - **Port:** 2221 (Site 1) or 2222 (Site 2)
   - **Logon Type:** Key file
   - **User:** ftpuser1 or ftpuser2
   - **Key file:** Browse to ssh-keys/site1/id_rsa
5. Click "Connect"

### File Locations
- Site 1 files: `/home/ftpuser1/wordpress/`
- Site 2 files: `/home/ftpuser2/wordpress/`

---

## PHPMyAdmin Access

### MySQL (Site 1)
- URL: `http://your-server-ip:8080`
- Server: mysql
- Username: root
- Password: (from .env MYSQL_ROOT_PASSWORD)

### MariaDB (Site 2)
- URL: `http://your-server-ip:8081`
- Server: mariadb
- Username: root
- Password: (from .env MARIADB_ROOT_PASSWORD)

**Security Warning:** In production, restrict PHPMyAdmin access by IP or disable it entirely.

---

## Troubleshooting

### Services Won't Start

```bash
# Check logs
docker-compose logs

# Check specific service
docker-compose logs nginx
docker-compose logs wordpress1

# Check port conflicts
sudo netstat -tulpn | grep -E ':(80|443|2221|2222|8080|8081)'

# Restart Docker
sudo systemctl restart docker
docker-compose down
docker-compose up -d
```

### Database Connection Error

```bash
# Verify database is running
docker-compose ps mysql mariadb

# Check environment variables
docker-compose exec wordpress1 env | grep WORDPRESS_DB

# Restart WordPress
docker-compose restart wordpress1 wordpress2
```

### NGINX 502 Bad Gateway

```bash
# Check PHP-FPM is running
docker-compose ps wordpress1 wordpress2

# Check NGINX logs
docker-compose logs nginx

# Test network connectivity
docker-compose exec nginx ping wordpress1

# Restart services
docker-compose restart nginx wordpress1 wordpress2
```

### Permission Issues

```bash
# Fix WordPress permissions
docker-compose exec wordpress1 chown -R www-data:www-data /var/www/html
docker-compose exec wordpress2 chown -R www-data:www-data /var/www/html
```

### SFTP Connection Refused

```bash
# Check SFTP containers
docker-compose ps sftp-site1 sftp-site2

# Check logs
docker-compose logs sftp-site1

# Verify SSH key permissions
ls -la ssh-keys/site1/

# Restart SFTP
docker-compose restart sftp-site1 sftp-site2
```

### Out of Disk Space

```bash
# Check disk usage
df -h

# Clean up Docker
docker system prune -a

# Remove unused volumes
docker volume prune
```

---

## Useful Commands

### Service Management
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart specific service
docker-compose restart nginx

# View logs (follow mode)
docker-compose logs -f

# View logs for specific service
docker-compose logs -f wordpress1

# Check service status
docker-compose ps

# Execute command in container
docker-compose exec wordpress1 bash
```

### Backup

#### Backup WordPress Files
```bash
# Site 1
docker run --rm --volumes-from wordpress-site1 -v $(pwd)/backups:/backup ubuntu tar czf /backup/site1-$(date +%Y%m%d).tar.gz /var/www/html

# Site 2
docker run --rm --volumes-from wordpress-site2 -v $(pwd)/backups:/backup ubuntu tar czf /backup/site2-$(date +%Y%m%d).tar.gz /var/www/html
```

#### Backup Databases
```bash
# MySQL (Site 1)
docker-compose exec mysql mysqldump -u root -p wordpress_site1 > backups/site1-db-$(date +%Y%m%d).sql

# MariaDB (Site 2)
docker-compose exec mariadb mysqldump -u root -p wordpress_site2 > backups/site2-db-$(date +%Y%m%d).sql
```

### Restore

#### Restore Database
```bash
# Site 1
docker-compose exec -T mysql mysql -u root -p wordpress_site1 < backups/site1-db-20240210.sql

# Site 2
docker-compose exec -T mariadb mysql -u root -p wordpress_site2 < backups/site2-db-20240210.sql
```

### Monitoring
```bash
# Resource usage
docker stats

# Disk usage
docker system df

# Network inspection
docker network inspect wordpress-multisite_wordpress-network
```

---

## Production Checklist

- [ ] Change all default passwords in .env
- [ ] Update domain names in NGINX configs
- [ ] Configure DNS records
- [ ] Install SSL certificates
- [ ] Restrict PHPMyAdmin access by IP
- [ ] Setup automated backups
- [ ] Configure firewall rules
- [ ] Enable Docker auto-start: `sudo systemctl enable docker`
- [ ] Setup monitoring and alerts
- [ ] Document credentials securely
- [ ] Test disaster recovery process
- [ ] Configure log rotation
- [ ] Setup automatic security updates

---

## Support

For issues or questions:
1. Check DOCKER-SETUP.md for detailed documentation
2. Review logs: `docker-compose logs`
3. Check Docker documentation: https://docs.docker.com
4. WordPress documentation: https://wordpress.org/support

---

## Next Steps

After installation:
1. Install WordPress themes and plugins
2. Configure WordPress settings
3. Setup email (SMTP plugin recommended)
4. Install security plugins (Wordfence, iThemes Security)
5. Setup caching (Redis, W3 Total Cache)
6. Configure CDN if needed
7. Setup regular backups
8. Monitor performance and logs
