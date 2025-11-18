# MySQL on Render - Production Ready

This is a production-ready template repository for running [MySQL](https://www.mysql.com) on Render as a private service.

## Features

✅ **Production-Ready Configuration**
- Optimized performance settings for InnoDB
- Security hardening (disabled local-infile, strict SQL mode)
- Comprehensive logging (error, slow query, binary logs)
- UTF8MB4 character set support

✅ **Reliability**
- Built-in health checks
- Binary logging for point-in-time recovery
- Automated backup scripts with rotation
- Initialization scripts for database setup

✅ **Security**
- Runs in Render's private network (not exposed to public Internet)
- Security hardening scripts
- Configurable user management

✅ **Monitoring & Maintenance**
- Slow query logging
- Error logging
- Health check endpoints
- Backup and restore utilities

## MySQL Version

This repository uses **MySQL 8.4.7**. You can change the version in the `Dockerfile` by modifying the `FROM` line. Available versions: https://hub.docker.com/r/mysql/mysql/tags/

## Quick Start

### Deploy to Render

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/render-examples/mysql)

### Manual Deployment

1. **Create a new Private Service** on Render
2. **Connect your repository** or use this template
3. **Configure Environment Variables** (see below)
4. **Add a Disk** for persistent storage (required)
5. **Deploy**

## Environment Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `MYSQL_ROOT_PASSWORD` | Root user password (required) | `your-secure-root-password` |
| `MYSQL_DATABASE` | Initial database to create (optional) | `myapp` |
| `MYSQL_USER` | Application user (optional) | `appuser` |
| `MYSQL_PASSWORD` | Application user password (required if MYSQL_USER is set) | `your-secure-password` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MYSQL_ROOT_HOST` | Host for root user | `%` (all hosts) |
| `MYSQL_CHARSET` | Character set | `utf8mb4` |
| `MYSQL_COLLATION` | Collation | `utf8mb4_unicode_ci` |

### Render-Specific Configuration

- **Instance Type**: Choose based on your workload (minimum 1GB RAM recommended)
- **Disk**: Add a persistent disk for data storage (minimum 10GB recommended)
- **Health Check Path**: Not applicable (health check is built into the container)

## Configuration

### MySQL Configuration

The MySQL configuration is located in `config/user.cnf`. Key settings include:

- **Performance**: InnoDB buffer pool, connection limits, query optimization
- **Security**: Strict SQL mode, disabled local-infile, secure file privileges
- **Logging**: Error logs, slow query logs, binary logs for replication/recovery
- **Character Set**: UTF8MB4 for full Unicode support

### Customizing Configuration

1. Edit `config/user.cnf` to adjust MySQL settings
2. Rebuild and redeploy the container

**Important**: Some settings like `innodb_buffer_pool_size` should be adjusted based on available memory. For Render instances:
- 1GB RAM: `innodb_buffer_pool_size=512M`
- 2GB RAM: `innodb_buffer_pool_size=1G`
- 4GB+ RAM: `innodb_buffer_pool_size=2G` or higher (70-80% of RAM)

## Initialization Scripts

Initialization scripts in `docker-entrypoint-initdb.d/` run automatically on first container start:

- `01-init.sql`: Database and user setup
- `02-security.sql`: Security hardening (removes test database, anonymous users)

**Note**: These scripts only run when the data directory is empty (first initialization).

## Backups

### Automated Backups

The `backups/` directory contains a backup container that can be used for scheduled backups.

#### Building the Backup Container

```bash
cd backups
docker build -t mysql-backup .
```

#### Running a Backup

```bash
docker run --rm \
  -e MYSQL_HOST=your-mysql-host \
  -e MYSQL_USER=root \
  -e MYSQL_PASSWORD=your-password \
  -v /path/to/backups:/var/lib/mysql/backups \
  -e RETENTION_DAYS=7 \
  -e COMPRESS=true \
  mysql-backup
```

#### Environment Variables for Backups

| Variable | Description | Default |
|----------|-------------|---------|
| `MYSQL_HOST` | MySQL hostname | Required |
| `MYSQL_USER` | MySQL user with backup privileges | Required |
| `MYSQL_PASSWORD` | MySQL user password | Required |
| `BACKUP_DIR` | Backup storage directory | `/var/lib/mysql/backups` |
| `RETENTION_DAYS` | Days to keep backups | `7` |
| `COMPRESS` | Compress backups (true/false) | `true` |

#### Scheduling Backups on Render

1. Create a **Cron Job** service
2. Use the backup container image
3. Set environment variables
4. Configure cron schedule (e.g., `0 2 * * *` for daily at 2 AM)

### Manual Backup

```bash
# Connect to your MySQL service
mysql -h your-mysql-host -u root -p

# Or use mysqldump
mysqldump -h your-mysql-host -u root -p --all-databases > backup.sql
```

### Restore from Backup

```bash
# Using the restore script
docker run --rm -it \
  -e MYSQL_HOST=your-mysql-host \
  -e MYSQL_USER=root \
  -e MYSQL_PASSWORD=your-password \
  -v /path/to/backups:/var/lib/mysql/backups \
  mysql-backup \
  /usr/local/bin/restore.sh /var/lib/mysql/backups/backup_20240101_120000.sql.gz

# Or manually
gunzip -c backup.sql.gz | mysql -h your-mysql-host -u root -p
```

## Monitoring

### Health Checks

The container includes a built-in health check that:
- Verifies MySQL is accepting connections
- Runs every 30 seconds
- Has a 10-second timeout
- Allows 40 seconds for initial startup

### Logs

Access logs through Render's dashboard or via:

```bash
# Error log
docker exec <container> tail -f /var/log/mysql/error.log

# Slow query log
docker exec <container> tail -f /var/log/mysql/slow-query.log
```

### Slow Query Analysis

Queries taking longer than 2 seconds are logged to the slow query log. To analyze:

```bash
# Install pt-query-digest (Percona Toolkit) or use mysqldumpslow
mysqldumpslow /var/log/mysql/slow-query.log
```

## Connecting to MySQL

### From Render Services

Since MySQL runs in Render's private network, connect using the internal hostname:

```bash
# Connection string format
mysql://user:password@mysql-service-name:3306/database_name

# Example (Node.js)
const mysql = require('mysql2');
const connection = mysql.createConnection({
  host: 'mysql-service-name',
  port: 3306,
  user: 'appuser',
  password: process.env.MYSQL_PASSWORD,
  database: 'myapp'
});
```

### From Local Machine (Development)

Use Render's SSH tunneling or expose the service temporarily for development.

## Security Best Practices

1. **Use Strong Passwords**: Generate secure passwords for root and application users
2. **Limit User Privileges**: Create application users with minimal required privileges
3. **Regular Updates**: Keep MySQL version updated
4. **Backup Encryption**: Consider encrypting backups for sensitive data
5. **Network Security**: Keep MySQL in private network (default on Render)
6. **Monitor Logs**: Regularly review error and slow query logs

## Performance Tuning

### Memory Settings

The default configuration is optimized for **512MB RAM** (Render Starter plan). Adjust `innodb_buffer_pool_size` in `config/user.cnf` based on available RAM:

**Current Settings (512MB RAM):**
- `innodb_buffer_pool_size=128M` (25% of RAM - conservative for small instances)
- `max_connections=50` (reduced to save memory)
- Binary logging disabled (saves memory and I/O)

**For Larger Instances:**
- 1GB RAM: `innodb_buffer_pool_size=512M`, `max_connections=100`
- 2GB RAM: `innodb_buffer_pool_size=1G`, `max_connections=200`
- 4GB+ RAM: `innodb_buffer_pool_size=2G+`, `max_connections=200+`

**General Rule:**
- Should be 70-80% of total available memory for larger instances
- For 512MB, use 25-30% to leave room for OS (~150MB) and MySQL overhead (~100MB)

### Connection Limits

Default `max_connections` is 200. Adjust based on your application's needs:
- Low traffic: 50-100
- Medium traffic: 200-500
- High traffic: 500-1000+

### Disk I/O

For better performance on Render:
- Use SSD-backed disks
- Consider increasing disk size for better IOPS
- Monitor disk usage and plan for growth

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed information about common warnings and issues.

### Common Warnings (All Addressed)

✅ **`--skip-host-cache` deprecated warning** - Fixed with `host_cache_size=0` in config  
⚠️ **Timezone file warnings** - Non-critical; MySQL image is minimal without package managers (see TROUBLESHOOTING.md)  
✅ **PID file location warning** - Fixed by setting secure PID file location  
⚠️ **Self-signed CA certificate** - Expected behavior for containerized MySQL (see TROUBLESHOOTING.md)  
⚠️ **Empty root password during init** - Expected during initialization phase (password is set after init)

### Container Won't Start

1. Check environment variables are set correctly
2. Verify disk is attached and has sufficient space
3. Review error logs: `docker logs <container>`

### Connection Issues

1. Verify service is in the same private network
2. Check firewall/security group settings
3. Confirm credentials are correct
4. Verify MySQL is listening: `docker exec <container> mysqladmin ping`

### Performance Issues

1. Review slow query log
2. Check `innodb_buffer_pool_size` setting
3. Monitor connection count
4. Analyze query execution plans

### Backup Failures

1. Verify MySQL credentials
2. Check disk space for backup storage
3. Ensure user has backup privileges
4. Review backup script logs

## Maintenance

### Updating MySQL Version

1. Update `FROM mysql:X.X.X` in `Dockerfile`
2. Test in staging environment
3. Backup current database
4. Deploy new version
5. Verify data integrity

### Database Maintenance

```sql
-- Optimize tables
OPTIMIZE TABLE table_name;

-- Analyze tables
ANALYZE TABLE table_name;

-- Check table status
SHOW TABLE STATUS;
```

## Resources

- [MySQL Documentation](https://dev.mysql.com/doc/)
- [Render MySQL Guide](https://render.com/docs/deploy-mysql)
- [Render Disks](https://render.com/docs/disks)
- [Render Private Services](https://render.com/docs/private-services)

## License

See [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
- Render Support: https://render.com/docs/support
- MySQL Community: https://dev.mysql.com/doc/refman/8.0/en/
