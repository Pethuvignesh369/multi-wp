# Docker WordPress Multi-Site Setup Guide

## Prerequisites
- Docker Engine 20.10 or higher
- Docker Compose 2.0 or higher
- At least 4GB RAM available
- Ports available: 80, 443, 2221, 2222, 8080, 8081

## Installation Steps

### 1. Install Docker (if not already installed)

#### Ubuntu/Debian
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

#### Amazon Linux 2
```bash
sudo yum update -y
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user
```

#### Install Docker Compose
```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. Configure Environment Variables
```bash
cp .env.example .env
nano .env
```

Update with secure passwords:
```env
MYSQL_ROOT_PASSWORD=your_secure_mysql_password
MARIADB_ROOT_PASSWORD=your_secure_mariadb_password
WP_SITE1_DB_PASSWORD=your_site1_password
WP_SITE2_DB_PASSWORD=your_site2_password
```

### 3. Update NGINX Configuration
Edit domain names in:
- `nginx/docker-site1.conf` - Change `site1.example.com` to your domain
- `nginx/docker-site2.conf` - Change `site2.example.com` to your domain

### 4. Start Docker Services
```bash
# Start all services in background
docker-compose up -d

# View logs
docker-compose logs -f

# Check service status
docker-compose ps
```

### 5. Access WordPress Setup

#### Site 1 (PHP 8.1 + MySQL)
1. Open http://localhost or your domain
2. Select language
3. Fill in site information:
   - Site Title: Your Site 1 Name
   - Username: admin
   - Password: (strong password)
   - Email: your@email.com
4. Click "Install WordPress"

#### Site 2 (PHP 8.4 + MariaDB)
1. Open http://site2.example.com
2. Follow same setup process as Site 1

### 6. Access PHPMyAdmin

#### For MySQL (Site 1)
- URL: http://localhost:8080
- Server: mysql
- Username: root
- Password: (from .env MYSQL_ROOT_PASSWORD)

#### For MariaDB (Site 2)
- URL: http://localhost:8081
- Server: mariadb
- Username: root
- Password: (from .env MARIADB_ROOT_PASSWORD)

### 7. Setup SFTP Access

#### Generate SSH Keys
```bash
mkdir -p ssh-keys/site1 ssh-keys/site2
ssh-keygen -t rsa -b 4096 -f ssh-keys/site1/id_rsa -N ""
ssh-keygen -t rsa -b 4096 -f ssh-keys/site2/id_rsa -N ""
```

#### Connect via SFTP

**Site 1:**
```bash
sftp -P 2221 -i ssh-keys/site1/id_rsa ftpuser1@localhost
```

**Site 2:**
```bash
sftp -P 2222 -i ssh-keys/site2/id_rsa ftpuser2@localhost
```

Or use FileZilla:
- Protocol: SFTP
- Host: localhost
- Port: 2221 (Site 1) or 2222 (Site 2)
- Logon Type: Key file
- User: ftpuser1 or ftpuser2
- Key file: ssh-keys/site1/id_rsa or ssh-keys/site2/id_rsa

## Docker Commands Reference

### Service Management
```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart specific service
docker-compose restart nginx

# View logs
docker-compose logs -f nginx
docker-compose logs -f wordpress1

# Execute command in container
docker-compose exec wordpress1 bash
```

### Backup and Restore

#### Backup WordPress Files
```bash
docker run --rm --volumes-from wordpress-site1 -v $(pwd)/backups:/backup ubuntu tar czf /backup/site1-files.tar.gz /var/www/html
```

#### Backup Database
```bash
docker-compose exec mysql mysqldump -u root -p wordpress_site1 > backups/site1-db.sql
docker-compose exec mariadb mysqldump -u root -p wordpress_site2 > backups/site2-db.sql
```

#### Restore Database
```bash
docker-compose exec -T mysql mysql -u root -p wordpress_site1 < backups/site1-db.sql
```

### Monitoring
```bash
# Check resource usage
docker stats

# View running containers
docker ps

# Inspect container
docker inspect wordpress-site1

# View container logs
docker logs wordpress-site1
```

## Troubleshooting

### Services won't start
```bash
# Check logs
docker-compose logs

# Check port conflicts
sudo netstat -tulpn | grep -E ':(80|443|2221|2222|8080|8081)'

# Restart Docker
sudo systemctl restart docker
```

### WordPress shows database connection error
```bash
# Check database is running
docker-compose ps mysql mariadb

# Verify environment variables
docker-compose exec wordpress1 env | grep WORDPRESS_DB

# Restart WordPress container
docker-compose restart wordpress1
```

### NGINX 502 Bad Gateway
```bash
# Check PHP-FPM is running
docker-compose ps wordpress1 wordpress2

# Check NGINX logs
docker-compose logs nginx

# Verify network connectivity
docker-compose exec nginx ping wordpress1
```

### Permission issues
```bash
# Fix WordPress permissions
docker-compose exec wordpress1 chown -R www-data:www-data /var/www/html
docker-compose exec wordpress2 chown -R www-data:www-data /var/www/html
```

## Security Best Practices

1. **Change default passwords** in .env file
2. **Use strong passwords** for WordPress admin
3. **Enable SSL/TLS** with Let's Encrypt:
   ```bash
   docker-compose exec nginx certbot --nginx -d site1.example.com
   ```
4. **Restrict PHPMyAdmin access** by IP in docker-compose.yml
5. **Regular backups** of volumes and databases
6. **Update images regularly**:
   ```bash
   docker-compose pull
   docker-compose up -d
   ```

## Production Deployment

### On EC2 or KymaCloud
1. Install Docker and Docker Compose
2. Clone repository
3. Configure .env with production values
4. Update domain names in NGINX configs
5. Start services: `docker-compose up -d`
6. Configure DNS to point to server IP
7. Setup SSL certificates
8. Configure firewall/security groups

### Ports to Open
- 80 (HTTP)
- 443 (HTTPS)
- 2221 (SFTP Site 1)
- 2222 (SFTP Site 2)
- 8080 (PHPMyAdmin MySQL) - Restrict by IP
- 8081 (PHPMyAdmin MariaDB) - Restrict by IP

## Scaling and Performance

### Increase PHP Memory
Edit docker-compose.yml and add to wordpress services:
```yaml
environment:
  PHP_MEMORY_LIMIT: 256M
```

### Add Redis Cache
Add to docker-compose.yml:
```yaml
redis:
  image: redis:alpine
  networks:
    - wordpress-network
```

### Enable NGINX Caching
Add to NGINX site configs:
```nginx
fastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=WORDPRESS:100m inactive=60m;
fastcgi_cache_key "$scheme$request_method$host$request_uri";
```
