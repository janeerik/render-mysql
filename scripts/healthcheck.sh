#!/bin/bash
# Health check script for MySQL container
# This script checks if MySQL is ready to accept connections

set -e

# Use mysqladmin ping (works without credentials for basic connectivity check)
# This checks if the MySQL server process is running and accepting connections
if mysqladmin ping -h localhost --silent 2>/dev/null; then
    exit 0
else
    exit 1
fi

