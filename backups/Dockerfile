# You can change this to a newer version of MySQL available at
# https://hub.docker.com/r/mysql/mysql/tags/
FROM mysql:8.0.44

RUN mkdir -p /var/lib/mysql/backups

CMD mysqldump -h "$MYSQL_HOST" -u "$MYSQL_USER" --password="$MYSQL_PASSWORD" \
    --single-transaction \
    --result-file=/var/lib/mysql/backups/backup.$(date +%F.%T).sql \
    --all-databases
