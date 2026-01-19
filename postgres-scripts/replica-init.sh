#!/bin/bash
set -e

# This script runs on PostgreSQL replica to initialize from master

# Check if data directory is empty (first run)
if [ -z "$(ls -A "$PGDATA" 2>/dev/null)" ] || [ ! -f "$PGDATA/PG_VERSION" ]; then
    echo "Initializing replica from master..."

    # Remove any existing data
    rm -rf "$PGDATA"/*

    # Wait for master PostgreSQL to be ready (not just container, but database)
    echo "Waiting for master database to be fully ready..."
    until PGPASSWORD=$POSTGRES_PASSWORD psql -h "$POSTGRES_MASTER_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c '\q' 2>/dev/null; do
        echo "Master database not ready yet, waiting..."
        sleep 3
    done

    echo "Master database is ready, waiting an additional 5 seconds for initialization to complete..."
    sleep 5

    # Now wait for replication user to be created
    echo "Checking if replication user exists..."
    until PGPASSWORD=$POSTGRES_REPLICATION_PASSWORD psql -h "$POSTGRES_MASTER_HOST" -U "$POSTGRES_REPLICATION_USER" -d "$POSTGRES_DB" -c '\q' 2>/dev/null; do
        echo "Replication user not ready yet, waiting..."
        sleep 2
    done

    echo "Starting pg_basebackup from master..."
    # Use pg_basebackup to clone from master
    PGPASSWORD=$POSTGRES_REPLICATION_PASSWORD pg_basebackup \
        -h "$POSTGRES_MASTER_HOST" \
        -D "$PGDATA" \
        -U "$POSTGRES_REPLICATION_USER" \
        -v \
        -P \
        -X stream \
        -C \
        -S replica_slot_$(hostname)

    # Create standby.signal file to mark as replica
    touch "$PGDATA/standby.signal"

    # Configure primary connection info
    cat >> "$PGDATA/postgresql.auto.conf" <<-EOF
primary_conninfo = 'host=$POSTGRES_MASTER_HOST port=5432 user=$POSTGRES_REPLICATION_USER password=$POSTGRES_REPLICATION_PASSWORD'
primary_slot_name = 'replica_slot_$(hostname)'
EOF

    echo "Replica initialization completed successfully"
else
    echo "Data directory already initialized, skipping pg_basebackup"
fi
