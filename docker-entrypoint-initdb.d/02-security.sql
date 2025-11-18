-- Security hardening script
-- Runs on first initialization

-- Remove anonymous users (if any)
DELETE FROM mysql.user WHERE User='' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Ensure root user has password (handled by MYSQL_ROOT_PASSWORD env var)
-- Additional root user security can be added here

-- Flush privileges to apply changes
FLUSH PRIVILEGES;

