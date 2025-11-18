# Troubleshooting Common Warnings and Issues

This document addresses common warnings and issues you may encounter when deploying MySQL on Render.

## Common Warnings and Their Solutions

### 1. `--skip-host-cache` is deprecated

**Warning:**
```
[Warning] [MY-011068] [Server] The syntax '--skip-host-cache' is deprecated and will be removed in a future release. Please use SET GLOBAL host_cache_size=0 instead.
```

**Status:** ✅ **FIXED** in current configuration

**Solution:** The configuration file now includes `host_cache_size=0` which replaces the deprecated `--skip-host-cache` option. This warning should no longer appear.

**If you still see it:** The warning may appear during the initialization phase before our config is fully loaded, but it should not appear during normal operation.

---

### 2. Timezone File Warnings

**Warning:**
```
Warning: Unable to load '/usr/share/zoneinfo/iso3166.tab' as time zone. Skipping it.
Warning: Unable to load '/usr/share/zoneinfo/leap-seconds.list' as time zone. Skipping it.
...
```

**Status:** ⚠️ **NON-CRITICAL** - Cannot be fixed in minimal image

**Explanation:** The MySQL Docker image is minimal and doesn't include package managers. While basic timezone data exists in `/usr/share/zoneinfo/`, some specific files like `iso3166.tab` and `leap-seconds.list` may be missing.

**Impact:** These warnings are non-critical - MySQL functions normally. Basic timezone operations work fine. The missing files are metadata files that MySQL uses for timezone information display, but don't affect core functionality.

**Workaround (if needed):** If you require full timezone support, you could:
1. Use a different base image that includes full timezone data
2. Mount timezone files from the host system
3. Ignore the warnings (recommended - they don't affect functionality)

---

### 3. Self-Signed CA Certificate Warning

**Warning:**
```
[Warning] [MY-010068] [Server] CA certificate ca.pem is self signed.
```

**Status:** ⚠️ **EXPECTED BEHAVIOR** - Not an error

**Explanation:** This is expected behavior for containerized MySQL deployments. The MySQL Docker image generates self-signed certificates by default for SSL/TLS connections.

**Impact:** None - MySQL functions normally. SSL connections are still encrypted, just not verified by a trusted Certificate Authority.

**If you need CA-signed certificates:**
1. Generate your own certificates
2. Mount them into the container at `/var/lib/mysql/ca.pem`, `/var/lib/mysql/server-cert.pem`, and `/var/lib/mysql/server-key.pem`
3. Configure MySQL to use them

**For production:** If you're connecting from external services that require CA verification, you'll need to provide proper certificates. For internal Render services, self-signed certificates are acceptable.

---

### 4. PID File Location Warning

**Warning:**
```
[Warning] [MY-011810] [Server] Insecure configuration for --pid-file: Location '/var/run/mysqld' in the path is accessible to all OS users. Consider choosing a different directory.
```

**Status:** ✅ **ADDRESSED** in current configuration

**Solution:** The configuration now sets `pid-file=/var/lib/mysql/mysqld.pid` which is more secure as it's within the MySQL data directory with restricted permissions.

**Note:** In containerized environments, this warning is often less critical since containers typically run as isolated processes. However, we've addressed it for better security practices.

---

### 5. Empty Root Password During Initialization

**Warning:**
```
[Warning] [MY-010453] [Server] root@localhost is created with an empty password ! Please consider switching off the --initialize-insecure option.
```

**Status:** ⚠️ **EXPECTED BEHAVIOR** during initialization

**Explanation:** This warning appears during the database initialization phase (first startup). The official MySQL Docker image uses `--initialize-insecure` to create the initial database structure, then sets the root password from `MYSQL_ROOT_PASSWORD` environment variable.

**Impact:** None - This is part of the normal initialization process. The root password is set immediately after initialization completes.

**Verification:** After initialization, verify the root password is set:
```sql
-- This should require a password
mysql -u root -p
```

**If you see this after initialization:** Check that `MYSQL_ROOT_PASSWORD` environment variable is set correctly in Render.

---

## Other Common Issues

### Container Won't Start

**Symptoms:** Container exits immediately or fails to start

**Check:**
1. **Environment Variables:**
   ```bash
   # Verify MYSQL_ROOT_PASSWORD is set
   echo $MYSQL_ROOT_PASSWORD
   ```

2. **Disk Space:**
   - Ensure persistent disk is attached
   - Check available disk space in Render dashboard

3. **Logs:**
   ```bash
   # Check container logs
   docker logs <container-name>
   ```

**Common Causes:**
- Missing `MYSQL_ROOT_PASSWORD` environment variable
- Insufficient disk space
- Disk not properly mounted
- Corrupted data directory

---

### Connection Refused

**Symptoms:** Cannot connect to MySQL from application

**Check:**
1. **Service Name:** Use the Render service name, not external URL
   ```bash
   # Correct
   mysql -h mysql-service-name -u user -p
   
   # Incorrect
   mysql -h mysql-service-name.onrender.com -u user -p
   ```

2. **Private Network:** Ensure both services are in the same private network

3. **Port:** Use port 3306 (default)

4. **Credentials:** Verify username and password are correct

---

### Performance Issues

**Symptoms:** Slow queries, high CPU usage, connection timeouts

**Solutions:**
1. **Check Slow Query Log:**
   ```bash
   docker exec <container> tail -f /var/log/mysql/slow-query.log
   ```

2. **Review Buffer Pool:**
   ```sql
   SHOW VARIABLES LIKE 'innodb_buffer_pool_size';
   SHOW STATUS LIKE 'Innodb_buffer_pool%';
   ```

3. **Adjust Configuration:**
   - Increase `innodb_buffer_pool_size` in `config/user.cnf`
   - Increase instance size in Render
   - Optimize slow queries

4. **Monitor Connections:**
   ```sql
   SHOW PROCESSLIST;
   SHOW STATUS LIKE 'Threads_connected';
   ```

---

### Backup Failures

**Symptoms:** Backup script fails or produces empty backups

**Check:**
1. **Credentials:**
   ```bash
   # Test connection
   mysql -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD -e "SELECT 1"
   ```

2. **Permissions:**
   ```sql
   -- Verify user has backup privileges
   SHOW GRANTS FOR 'backup_user'@'%';
   ```

3. **Disk Space:**
   ```bash
   df -h /var/lib/mysql/backups
   ```

4. **Backup Script:**
   ```bash
   # Run backup manually with verbose output
   bash -x /usr/local/bin/backup.sh
   ```

---

## Log Locations

All logs are accessible through Render's dashboard or via:

- **Error Log:** `/var/log/mysql/error.log`
- **Slow Query Log:** `/var/log/mysql/slow-query.log`
- **General Log:** `/var/log/mysql/general.log` (if enabled)
- **Binary Logs:** `/var/lib/mysql/mysql-bin.*`

**Access logs:**
```bash
# Via Render dashboard: Service → Logs tab
# Or via container:
docker exec <container> tail -f /var/log/mysql/error.log
```

---

## Getting Help

If you encounter issues not covered here:

1. **Check Render Documentation:**
   - [Render MySQL Guide](https://render.com/docs/deploy-mysql)
   - [Render Support](https://render.com/docs/support)

2. **MySQL Documentation:**
   - [MySQL 8.0 Reference Manual](https://dev.mysql.com/doc/refman/8.0/en/)

3. **Review Logs:**
   - Check error logs for specific error messages
   - Review slow query logs for performance issues

4. **Community Support:**
   - [MySQL Forums](https://forums.mysql.com/)
   - [Stack Overflow](https://stackoverflow.com/questions/tagged/mysql)

---

## Verification Checklist

After deployment, verify everything is working:

- [ ] Container starts without errors
- [ ] No critical warnings in logs (some informational warnings are OK)
- [ ] Can connect from application service
- [ ] Root password is set (requires password to connect)
- [ ] Application database exists
- [ ] Application user can connect
- [ ] Health checks are passing
- [ ] Backups are working (if configured)
- [ ] Logs are being written

