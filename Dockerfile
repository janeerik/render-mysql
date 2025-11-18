# You can change this to a newer version of MySQL available at
# https://hub.docker.com/r/mysql/mysql/tags/
FROM mysql:8.0.44

COPY config/user.cnf /etc/mysql/my.cnf
