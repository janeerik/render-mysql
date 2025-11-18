# Deployment Guide

This guide walks you through deploying MySQL to Render step-by-step.

## Prerequisites

- Render account (sign up at https://render.com)
- Git repository (GitHub, GitLab, or Bitbucket)
- Basic understanding of MySQL and Docker

## Step 1: Prepare Your Repository

1. **Fork or clone this repository**
   ```bash
   git clone https://github.com/your-username/render-mysql.git
   cd render-mysql
   ```

2. **Customize configuration** (optional)
   - Edit `config/user.cnf` if you need different MySQL settings
   - Adjust `innodb_buffer_pool_size` based on your instance size
   - Modify initialization scripts in `docker-entrypoint-initdb.d/` if needed

3. **Commit and push to your repository**
   ```bash
   git add .
   git commit -m "Configure MySQL for production"
   git push origin main
   ```

## Step 2: Deploy to Render

### Option A: Deploy via Dashboard (Recommended for first-time)

1. **Log in to Render Dashboard**
   - Go to https://dashboard.render.com

2. **Create New Private Service**
   - Click "New +" → "Private Service"
   - Connect your Git repository
   - Select this repository

3. **Configure Service**
   - **Name**: `mysql` (or your preferred name)
   - **Region**: Choose closest to your application
   - **Branch**: `main` (or your default branch)
   - **Root Directory**: Leave empty (or specify if in subdirectory)
   - **Runtime**: `Docker`
   - **Dockerfile Path**: `Dockerfile`
   - **Docker Context**: `.` (current directory)

4. **Set Environment Variables**
   Click "Advanced" → "Environment Variables" and add:
   
   **Required:**
   - `MYSQL_ROOT_PASSWORD`: Generate a strong password (use Render's secret feature)
   
   **Optional but Recommended:**
   - `MYSQL_DATABASE`: Your application database name (e.g., `myapp`)
   - `MYSQL_USER`: Application user (e.g., `appuser`)
   - `MYSQL_PASSWORD`: Application user password (use Render's secret feature)

5. **Add Persistent Disk**
   - Go to "Disks" section
   - Click "Add Disk"
   - **Name**: `mysql-data`
   - **Mount Path**: `/var/lib/mysql` (default for MySQL)
   - **Size**: Minimum 10GB (adjust based on your needs)
   - **Type**: SSD (recommended for performance)

6. **Choose Instance Type**
   - **Starter**: 512MB RAM (development/testing only)
   - **Standard**: 1GB RAM (small applications)
   - **Pro**: 2GB+ RAM (production recommended)
   
   **Note**: Adjust `innodb_buffer_pool_size` in `config/user.cnf` based on RAM:
   - 1GB RAM → 512M
   - 2GB RAM → 1G
   - 4GB+ RAM → 2G or higher

7. **Deploy**
   - Click "Create Private Service"
   - Wait for build and deployment (5-10 minutes)
   - Monitor logs for successful startup

### Option B: Deploy via Blueprint (render.yaml)

1. **Create render.yaml**
   ```bash
   cp render.yaml.example render.yaml
   ```

2. **Edit render.yaml**
   - Update service name if needed
   - Set environment variables (or use secret references)
   - Adjust instance plan

3. **Deploy**
   - Push `render.yaml` to your repository
   - Render will automatically detect and deploy
   - Or use Render CLI: `render deploy`

## Step 3: Verify Deployment

1. **Check Service Status**
   - Go to your service dashboard
   - Verify status is "Live" (green)
   - Check health check status

2. **Review Logs**
   - Click "Logs" tab
   - Look for: "MySQL init process done. Ready for start up"
   - Verify no errors

3. **Test Connection** (from another Render service)
   ```bash
   # In your application service
   mysql -h mysql -u appuser -p
   # Enter password when prompted
   ```

## Step 4: Set Up Backups (Recommended)

### Option A: Manual Backups

1. **Build backup container**
   ```bash
   docker build -f backups/Dockerfile -t mysql-backup .
   ```

2. **Run backup**
   ```bash
   docker run --rm \
     -e MYSQL_HOST=mysql \
     -e MYSQL_USER=root \
     -e MYSQL_PASSWORD=your-root-password \
     -v $(pwd)/backups:/var/lib/mysql/backups \
     mysql-backup
   ```

### Option B: Automated Backups (Cron Job)

1. **Create Cron Job Service**
   - Click "New +" → "Cron Job"
   - Connect same repository
   - **Schedule**: `0 2 * * *` (daily at 2 AM UTC)

2. **Configure**
   - **Dockerfile Path**: `backups/Dockerfile`
   - **Docker Context**: `.`

3. **Set Environment Variables**
   - `MYSQL_HOST`: Your MySQL service name
   - `MYSQL_USER`: `root` (or backup user)
   - `MYSQL_PASSWORD`: Root password (use secret)
   - `RETENTION_DAYS`: `7` (or your preference)
   - `COMPRESS`: `true`

4. **Add Disk for Backups**
   - Mount path: `/var/lib/mysql/backups`
   - Size: Based on retention policy

## Step 5: Connect Your Application

### From Render Service (Same Private Network)

**Connection String Format:**
```
mysql://user:password@mysql-service-name:3306/database_name
```

**Example (Node.js):**
```javascript
const mysql = require('mysql2/promise');

const connection = await mysql.createConnection({
  host: 'mysql',  // Your MySQL service name
  port: 3306,
  user: process.env.MYSQL_USER,
  password: process.env.MYSQL_PASSWORD,
  database: process.env.MYSQL_DATABASE
});
```

**Example (Python):**
```python
import mysql.connector

conn = mysql.connector.connect(
    host='mysql',  # Your MySQL service name
    port=3306,
    user=os.environ['MYSQL_USER'],
    password=os.environ['MYSQL_PASSWORD'],
    database=os.environ['MYSQL_DATABASE']
)
```

**Example (Environment Variables in Application Service):**
```
MYSQL_HOST=mysql
MYSQL_PORT=3306
MYSQL_USER=appuser
MYSQL_PASSWORD=${MYSQL_PASSWORD}  # Reference secret
MYSQL_DATABASE=myapp
```

## Troubleshooting

### Service Won't Start

**Check:**
1. Environment variables are set correctly
2. Disk is attached and mounted
3. Sufficient disk space
4. Review error logs

**Common Issues:**
- Missing `MYSQL_ROOT_PASSWORD`: Service will fail immediately
- Disk not attached: Data won't persist
- Insufficient memory: Adjust instance size or buffer pool

### Connection Issues

**Check:**
1. Services are in same private network
2. Using correct service name (not external URL)
3. Credentials are correct
4. MySQL is running (check health status)

**Test Connection:**
```bash
# From another Render service
mysqladmin -h mysql -u root -p ping
```

### Performance Issues

**Check:**
1. Slow query log: `docker exec <container> tail -f /var/log/mysql/slow-query.log`
2. Connection count: `SHOW PROCESSLIST;`
3. Buffer pool usage: `SHOW STATUS LIKE 'Innodb_buffer_pool%';`
4. Disk I/O: Monitor in Render dashboard

**Solutions:**
- Increase instance size
- Adjust `innodb_buffer_pool_size`
- Optimize queries
- Add indexes

## Next Steps

1. **Monitor Performance**
   - Set up alerts in Render dashboard
   - Review slow query logs regularly
   - Monitor disk usage

2. **Security Hardening**
   - Create application-specific users with minimal privileges
   - Regularly rotate passwords
   - Review access logs

3. **Backup Strategy**
   - Test restore procedures
   - Store backups off-site (S3, etc.)
   - Document recovery procedures

4. **Scaling**
   - Monitor resource usage
   - Plan for vertical scaling (larger instance)
   - Consider read replicas for high-traffic applications

## Additional Resources

- [Render MySQL Documentation](https://render.com/docs/deploy-mysql)
- [MySQL Performance Tuning](https://dev.mysql.com/doc/refman/8.0/en/optimization.html)
- [Render Support](https://render.com/docs/support)

