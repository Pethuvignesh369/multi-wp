-- Create databases for WordPress sites
CREATE DATABASE IF NOT EXISTS wordpress_site1 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS wordpress_site2 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create database users
CREATE USER IF NOT EXISTS 'wp_site1'@'localhost' IDENTIFIED BY 'CHANGE_THIS_PASSWORD_1';
CREATE USER IF NOT EXISTS 'wp_site2'@'localhost' IDENTIFIED BY 'CHANGE_THIS_PASSWORD_2';

-- Grant privileges
GRANT ALL PRIVILEGES ON wordpress_site1.* TO 'wp_site1'@'localhost';
GRANT ALL PRIVILEGES ON wordpress_site2.* TO 'wp_site2'@'localhost';

-- Flush privileges
FLUSH PRIVILEGES;
