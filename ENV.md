# Environment Variables Reference

This document provides detailed information about all environment variables used in this MySQL deployment.

## Required Environment Variables

### `MYSQL_ROOT_PASSWORD`
- **Description**: Password for the MySQL root user
- **Required**: Yes
- **Example**: `MySecureP@ssw0rd123!`
- **Security**: Use a strong, randomly generated password. Store in Render's environment variable secrets.
- **Note**: This is the only required variable. If not set, MySQL will fail to start.

## Optional Environment Variables

### Database Initialization

#### `MYSQL_DATABASE`
- **Description**: Name of the database to create on first initialization
- **Required**: No
- **Example**: `myapp`, `production_db`
- **Note**: Only created if the data directory is empty (first run)

#### `MYSQL_USER`
- **Description**: Username for an application-specific MySQL user
- **Required**: No (but recommended for production)
- **Example**: `appuser`, `webapp`
- **Note**: User is granted all privileges on `MYSQL_DATABASE` if set

#### `MYSQL_PASSWORD`
- **Description**: Password for the user specified in `MYSQL_USER`
- **Required**: Yes, if `MYSQL_USER` is set
- **Example**: `AppUserP@ssw0rd456!`
- **Security**: Use a strong password different from root password

#### `MYSQL_ROOT_HOST`
- **Description**: Host from which root user can connect
- **Required**: No
- **Default**: `%` (all hosts)
- **Example**: `localhost`, `%`, `192.168.1.%`
- **Security**: Consider restricting to specific hosts for better security

### Character Set Configuration

#### `MYSQL_CHARSET`
- **Description**: Default character set for new databases
- **Required**: No
- **Default**: `utf8mb4`
- **Example**: `utf8mb4`, `utf8`, `latin1`
- **Note**: UTF8MB4 is recommended for full Unicode support (emojis, etc.)

#### `MYSQL_COLLATION`
- **Description**: Default collation for new databases
- **Required**: No
- **Default**: `utf8mb4_unicode_ci`
- **Example**: `utf8mb4_unicode_ci`, `utf8mb4_general_ci`
- **Note**: `unicode_ci` is more accurate but slightly slower than `general_ci`

## Backup Container Environment Variables

These variables are used when running the backup container:

### `MYSQL_HOST`
- **Description**: Hostname or IP address of the MySQL server
- **Required**: Yes (for backups)
- **Example**: `mysql-service-name`, `mysql.internal`, `10.0.0.5`
- **Note**: Use the Render service name for private network connections

### `MYSQL_USER`
- **Description**: MySQL user with backup privileges
- **Required**: Yes (for backups)
- **Example**: `root`, `backup_user`
- **Privileges**: Requires `SELECT`, `SHOW VIEW`, `TRIGGER`, `LOCK TABLES` at minimum

### `MYSQL_PASSWORD`
- **Description**: Password for the backup user
- **Required**: Yes (for backups)
- **Example**: `BackupP@ssw0rd789!`

### `BACKUP_DIR`
- **Description**: Directory where backups are stored
- **Required**: No
- **Default**: `/var/lib/mysql/backups`
- **Example**: `/backups`, `/data/backups`
- **Note**: Mount a volume to persist backups outside the container

### `RETENTION_DAYS`
- **Description**: Number of days to keep backup files
- **Required**: No
- **Default**: `7`
- **Example**: `30`, `90`, `365`
- **Note**: Older backups are automatically deleted

### `COMPRESS`
- **Description**: Whether to compress backup files with gzip
- **Required**: No
- **Default**: `true`
- **Example**: `true`, `false`
- **Note**: Compression saves disk space but takes longer

## Setting Environment Variables on Render

### Via Dashboard

1. Go to your service settings
2. Navigate to "Environment" section
3. Click "Add Environment Variable"
4. Enter variable name and value
5. Mark sensitive variables as "Secret" (they'll be encrypted)

### Via Render Blueprint (render.yaml)

```yaml
services:
  - type: pserv
    name: mysql
    envVars:
      - key: MYSQL_ROOT_PASSWORD
        sync: false
        value: ${MYSQL_ROOT_PASSWORD}
      - key: MYSQL_DATABASE
        value: myapp
      - key: MYSQL_USER
        value: appuser
      - key: MYSQL_PASSWORD
        sync: false
        value: ${MYSQL_PASSWORD}
```

### Via CLI

```bash
render env:set MYSQL_ROOT_PASSWORD "your-password" --service mysql
```

## Security Best Practices

1. **Never commit passwords to git**: Use Render's environment variable secrets
2. **Use strong passwords**: Minimum 16 characters, mix of letters, numbers, symbols
3. **Rotate passwords regularly**: Update passwords periodically
4. **Limit root access**: Create application users with minimal privileges
5. **Use different passwords**: Root and application users should have different passwords
6. **Enable secrets sync**: Use Render's secret sync for team environments

## Generating Secure Passwords

### Using OpenSSL
```bash
openssl rand -base64 32
```

### Using Python
```python
import secrets
import string
alphabet = string.ascii_letters + string.digits + string.punctuation
password = ''.join(secrets.choice(alphabet) for i in range(32))
print(password)
```

### Using Node.js
```javascript
const crypto = require('crypto');
const password = crypto.randomBytes(32).toString('base64');
console.log(password);
```

## Environment Variable Validation

The MySQL container will validate required variables on startup:
- If `MYSQL_ROOT_PASSWORD` is missing, the container will exit with an error
- If `MYSQL_USER` is set but `MYSQL_PASSWORD` is missing, initialization will fail
- Invalid character set or collation values will cause MySQL to use defaults

## Troubleshooting

### Variable Not Applied
- Check variable name spelling (case-sensitive)
- Verify variable is set in Render dashboard
- Restart the service after adding variables
- Check container logs for initialization errors

### Password Issues
- Ensure no special characters need escaping
- Check for leading/trailing spaces
- Verify password meets MySQL requirements (if any)

### Connection Issues
- Verify `MYSQL_HOST` uses correct service name
- Check that services are in the same private network
- Confirm credentials match environment variables

