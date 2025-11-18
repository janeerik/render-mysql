# MySQL Backup Container
# This container can be used for scheduled backups or one-time backup operations
# Build from project root: docker build -f backups/Dockerfile -t mysql-backup .
FROM mysql:8.4.7

# Note: The MySQL image is minimal and doesn't include package managers.
# gzip and find are already available in the base MySQL image, so no installation needed.

# Create backup directory
RUN mkdir -p /var/lib/mysql/backups

# Copy backup scripts
# Note: Build context should be project root, not backups directory
COPY backups/backup.sh /usr/local/bin/backup.sh
COPY backups/restore.sh /usr/local/bin/restore.sh
RUN chmod +x /usr/local/bin/backup.sh /usr/local/bin/restore.sh

# Default command runs backup
# Override with: docker run ... restore.sh <backup_file> for restore operations
CMD ["/usr/local/bin/backup.sh"]
