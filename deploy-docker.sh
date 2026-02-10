#!/bin/bash
# Docker WordPress Multi-Site Deployment Script
# For EC2, KymaCloud, or any Linux server

set -e

echo "=== WordPress Multi-Site Docker Deployment ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS"
    exit 1
fi

echo "Detected OS: $OS"
echo ""

# Install Docker
echo "=== Installing Docker ==="
if ! command -v docker &> /dev/null; then
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        apt-get update
        apt-get install -y ca-certificates curl gnupg lsb-release
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    elif [ "$OS" = "amzn" ]; then
        yum update -y
        yum install -y docker
        service docker start
        systemctl enable docker
    else
        echo "Unsupported OS for automatic Docker installation"
        echo "Please install Docker manually: https://docs.docker.com/engine/install/"
        exit 1
    fi
    echo "Docker installed successfully"
else
    echo "Docker already installed"
fi

# Install Docker Compose
echo ""
echo "=== Installing Docker Compose ==="
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed successfully"
else
    echo "Docker Compose already installed"
fi

# Verify installations
echo ""
echo "=== Verifying Installations ==="
docker --version
docker-compose --version

# Create necessary directories
echo ""
echo "=== Creating Directories ==="
mkdir -p logs/nginx
mkdir -p ssh-keys/site1
mkdir -p ssh-keys/site2
mkdir -p backups

# Setup environment file
echo ""
echo "=== Setting up Environment Variables ==="
if [ ! -f .env ]; then
    cp .env.example .env
    
    # Generate random passwords
    MYSQL_ROOT_PASS=$(openssl rand -base64 32)
    MARIADB_ROOT_PASS=$(openssl rand -base64 32)
    WP_SITE1_PASS=$(openssl rand -base64 32)
    WP_SITE2_PASS=$(openssl rand -base64 32)
    
    # Update .env file
    sed -i "s/your_mysql_root_password/$MYSQL_ROOT_PASS/" .env
    sed -i "s/your_mariadb_root_password/$MARIADB_ROOT_PASS/" .env
    sed -i "s/your_site1_db_password/$WP_SITE1_PASS/" .env
    sed -i "s/your_site2_db_password/$WP_SITE2_PASS/" .env
    
    echo "Generated secure passwords in .env file"
    echo "IMPORTANT: Save these credentials!"
    echo ""
    cat .env
    echo ""
else
    echo ".env file already exists, skipping..."
fi

# Generate SSH keys for SFTP
echo ""
echo "=== Generating SSH Keys for SFTP ==="
if [ ! -f ssh-keys/site1/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -f ssh-keys/site1/id_rsa -N "" -C "site1-sftp"
    echo "Generated SSH key for Site 1"
fi
if [ ! -f ssh-keys/site2/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -f ssh-keys/site2/id_rsa -N "" -C "site2-sftp"
    echo "Generated SSH key for Site 2"
fi

# Set permissions
chmod 600 ssh-keys/site1/id_rsa
chmod 600 ssh-keys/site2/id_rsa
chmod 644 ssh-keys/site1/id_rsa.pub
chmod 644 ssh-keys/site2/id_rsa.pub

# Configure firewall (if ufw is available)
echo ""
echo "=== Configuring Firewall ==="
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 2221/tcp
    ufw allow 2222/tcp
    echo "Firewall rules added (run 'ufw enable' to activate)"
else
    echo "UFW not found, skipping firewall configuration"
    echo "Make sure ports 22, 80, 443, 2221, 2222 are open in your security group"
fi

# Pull Docker images
echo ""
echo "=== Pulling Docker Images ==="
docker-compose pull

# Start services
echo ""
echo "=== Starting Docker Services ==="
docker-compose up -d

# Wait for services to be ready
echo ""
echo "Waiting for services to start..."
sleep 10

# Check service status
echo ""
echo "=== Service Status ==="
docker-compose ps

# Display access information
echo ""
echo "=== Deployment Complete! ==="
echo ""
echo "Access your services at:"
echo "  Site 1 (PHP 8.1):        http://$(curl -s ifconfig.me)"
echo "  Site 2 (PHP 8.4):        http://site2.example.com (update DNS)"
echo "  PHPMyAdmin (MySQL):      http://$(curl -s ifconfig.me):8080"
echo "  PHPMyAdmin (MariaDB):    http://$(curl -s ifconfig.me):8081"
echo "  SFTP Site 1:             sftp -P 2221 ftpuser1@$(curl -s ifconfig.me)"
echo "  SFTP Site 2:             sftp -P 2222 ftpuser2@$(curl -s ifconfig.me)"
echo ""
echo "Next steps:"
echo "1. Update DNS records to point your domains to this server"
echo "2. Update nginx/docker-site1.conf and nginx/docker-site2.conf with your domains"
echo "3. Restart NGINX: docker-compose restart nginx"
echo "4. Complete WordPress setup by visiting your site URLs"
echo "5. Install SSL certificates (see DOCKER-SETUP.md)"
echo ""
echo "Database credentials are saved in .env file"
echo "SSH keys for SFTP are in ssh-keys/ directory"
echo ""
echo "View logs: docker-compose logs -f"
echo "Stop services: docker-compose down"
echo ""
