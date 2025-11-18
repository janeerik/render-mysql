#!/bin/bash
# MySQL backup script with rotation and compression

set -e

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/var/lib/mysql/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
COMPRESS="${COMPRESS:-true}"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Generate backup filename with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_${TIMESTAMP}.sql"

# Perform backup
echo "Starting MySQL backup at $(date)"
mysqldump \
    -h "$MYSQL_HOST" \
    -u "$MYSQL_USER" \
    --password="$MYSQL_PASSWORD" \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --all-databases \
    --result-file="$BACKUP_FILE" \
    --verbose

# Compress backup if enabled
if [ "$COMPRESS" = "true" ]; then
    echo "Compressing backup..."
    gzip "$BACKUP_FILE"
    BACKUP_FILE="${BACKUP_FILE}.gz"
fi

# Verify backup file exists and has content
if [ ! -s "$BACKUP_FILE" ]; then
    echo "ERROR: Backup file is empty or does not exist!"
    exit 1
fi

echo "Backup completed successfully: $BACKUP_FILE"
echo "Backup size: $(du -h "$BACKUP_FILE" | cut -f1)"

# Clean up old backups (retention policy)
if [ "$RETENTION_DAYS" -gt 0 ]; then
    echo "Cleaning up backups older than $RETENTION_DAYS days..."
    find "$BACKUP_DIR" -name "backup_*.sql*" -type f -mtime +$RETENTION_DAYS -delete
    echo "Cleanup completed"
fi

# List current backups
echo "Current backups:"
ls -lh "$BACKUP_DIR"/backup_*.sql* 2>/dev/null || echo "No backups found"

