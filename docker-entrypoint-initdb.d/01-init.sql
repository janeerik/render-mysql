-- Initialization script for MySQL database
-- This script runs only on first container initialization

-- Create application database (if MYSQL_DATABASE is set)
-- The official MySQL image handles this automatically, but we can add custom logic here

-- Create additional databases if needed
-- CREATE DATABASE IF NOT EXISTS `app_db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Grant privileges (MYSQL_USER and MYSQL_PASSWORD are handled by the official image)
-- Additional users can be created here if needed

-- Example: Create a read-only user
-- CREATE USER IF NOT EXISTS 'readonly'@'%' IDENTIFIED BY 'your_secure_password';
-- GRANT SELECT ON *.* TO 'readonly'@'%';
-- FLUSH PRIVILEGES;

-- Set timezone
SET GLOBAL time_zone = '+00:00';

