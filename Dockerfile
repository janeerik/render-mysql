# You can change this to a newer version of MySQL available at
# https://hub.docker.com/r/mysql/mysql/tags/
FROM mysql:8.4.7

# Note: The MySQL image is minimal and doesn't include package managers.
# Timezone warnings are non-critical - MySQL functions normally without full timezone data.
# If you need full timezone support, consider using a different base image or
# mounting timezone files from the host.

# Create log directory and ensure proper permissions
RUN mkdir -p /var/log/mysql && \
    chown -R mysql:mysql /var/log/mysql

# Copy MySQL configuration
COPY config/user.cnf /etc/mysql/conf.d/user.cnf

# Copy initialization scripts
COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/

# Copy health check script
COPY scripts/healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

# Set health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh || exit 1
