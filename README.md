# WordPress Multi-Site EC2 Deployment

This repository contains all necessary files to deploy a multi-site WordPress setup on AWS EC2 with the following architecture:

## Architecture
- **NGINX**: Reverse proxy and web server
- **Site 1**: WordPress with PHP 8.1 + MySQL
- **Site 2**: WordPress with PHP 8.4 + MariaDB
- **PHPMyAdmin**: Database management interface
- **FTP/SFTP**: Secure file transfer access

## Files Included
- `deploy.sh` - Main deployment script
- `nginx/nginx.conf` - Main NGINX configuration
- `nginx/site1.conf` - Site 1 NGINX configuration (PHP 8.1)
- `nginx/site2.conf` - Site 2 NGINX configuration (PHP 8.4)
- `setup-databases.sql` - Database setup script
- `INSTALLATION.md` - Detailed installation guide

## Quick Start
1. Launch Ubuntu EC2 instance
2. Upload these files to your instance
3. Run `sudo ./deploy.sh`
4. Follow steps in INSTALLATION.md

## Requirements
- Ubuntu 20.04 or 22.04
- At least 2GB RAM (t2.small or larger recommended)
- 20GB+ storage
- Security group with ports 22, 80, 443 open

See INSTALLATION.md for complete setup instructions.
