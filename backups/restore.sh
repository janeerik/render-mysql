#!/bin/bash
# MySQL restore script

set -e

# Check if backup file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file.sql[.gz]>"
    echo "Example: $0 /var/lib/mysql/backups/backup_20240101_120000.sql.gz"
    exit 1
fi

BACKUP_FILE="$1"

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: Backup file not found: $BACKUP_FILE"
    exit 1
fi

# Confirm restore
echo "WARNING: This will restore the database from: $BACKUP_FILE"
echo "This operation will overwrite existing data!"
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

# Determine if file is compressed
if [[ "$BACKUP_FILE" == *.gz ]]; then
    echo "Decompressing and restoring backup..."
    gunzip -c "$BACKUP_FILE" | mysql \
        -h "$MYSQL_HOST" \
        -u "$MYSQL_USER" \
        --password="$MYSQL_PASSWORD" \
        --verbose
else
    echo "Restoring backup..."
    mysql \
        -h "$MYSQL_HOST" \
        -u "$MYSQL_USER" \
        --password="$MYSQL_PASSWORD" \
        --verbose < "$BACKUP_FILE"
fi

echo "Restore completed successfully!"

