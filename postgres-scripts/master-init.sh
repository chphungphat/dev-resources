#!/bin/bash
set -e

# This script runs on PostgreSQL master initialization
# It creates a replication user and configures pg_hba.conf for replication

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create replication user
    CREATE USER ${POSTGRES_REPLICATION_USER} WITH REPLICATION ENCRYPTED PASSWORD '${POSTGRES_REPLICATION_PASSWORD}';

    -- Grant necessary permissions
    GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_REPLICATION_USER};
EOSQL

# Add replication entry to pg_hba.conf
echo "host replication ${POSTGRES_REPLICATION_USER} 0.0.0.0/0 scram-sha-256" >> "$PGDATA/pg_hba.conf"

# Reload PostgreSQL configuration
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "SELECT pg_reload_conf();"

echo "Master replication setup completed successfully"
