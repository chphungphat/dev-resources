# PostgreSQL Replication Setup Guide

This setup automatically configures PostgreSQL master-replica (primary-standby) replication using initialization scripts.

## How It Works

### Master (Primary) Server

1. **Initialization Script**: `postgres-scripts/master-init.sh`
   - Automatically runs on first container startup via `/docker-entrypoint-initdb.d/`
   - Creates a dedicated replication user
   - Configures `pg_hba.conf` to allow replication connections
   - Reloads PostgreSQL configuration

2. **Configuration**:
   - WAL level set to `replica` for streaming replication
   - Configured to support up to 3 replicas (`max_wal_senders=3`)
   - Up to 3 replication slots available

3. **Healthcheck**:
   - Ensures master is ready before replica starts

### Replica (Standby) Server

1. **Initialization Script**: `postgres-scripts/replica-init.sh`
   - Runs before PostgreSQL starts
   - Waits for master to be healthy
   - Uses `pg_basebackup` to clone data from master
   - Creates `standby.signal` file to enable standby mode
   - Configures connection to primary server

2. **Automatic Recovery**:
   - If data directory is already initialized, skips cloning
   - Continues replication from existing state

## Starting the Services

### First Time Setup

```bash
# Start master first
./dc up -d postgres-master

# Wait for master to be healthy (check with)
./dc ps postgres-master

# Start replica (will automatically clone from master)
./dc up -d postgres-replica
```

### Verify Replication

**On Master:**
```bash
# Check replication connections
./dc exec postgres-master psql -U admin -d mydb -c "SELECT * FROM pg_stat_replication;"

# Check replication slots
./dc exec postgres-master psql -U admin -d mydb -c "SELECT * FROM pg_replication_slots;"
```

**On Replica:**
```bash
# Check if in recovery mode (should return 't' for true)
./dc exec postgres-replica psql -U admin -d mydb -c "SELECT pg_is_in_recovery();"

# Check replication status
./dc exec postgres-replica psql -U admin -d mydb -c "SELECT status, receive_start_lsn, latest_end_lsn FROM pg_stat_wal_receiver;"
```

## Testing Replication

1. **Create test data on master:**
```bash
./dc exec postgres-master psql -U admin -d mydb -c "CREATE TABLE test_replication (id SERIAL PRIMARY KEY, data TEXT);"
./dc exec postgres-master psql -U admin -d mydb -c "INSERT INTO test_replication (data) VALUES ('test data');"
```

2. **Verify data on replica:**
```bash
./dc exec postgres-replica psql -U admin -d mydb -c "SELECT * FROM test_replication;"
```

## Important Notes

- **First Time Only**: Replication setup happens automatically on first startup
- **Data Directory**: If you need to re-initialize, stop containers and remove volumes:
  ```bash
  ./dc down
  docker volume rm resources_postgres-master-data resources_postgres-replica-data
  ```
- **Read-Only Replica**: The replica is read-only and cannot accept writes
- **Automatic Failover**: This setup does NOT include automatic failover. For production, consider using tools like Patroni or repmgr.

## Configuration Files

- `postgres-scripts/master-init.sh`: Master initialization
- `postgres-scripts/replica-init.sh`: Replica initialization and cloning
- `.env.services`: Contains credentials for replication user

## Environment Variables

```env
POSTGRES_USER=admin                           # Main database user
POSTGRES_PASSWORD=admin123                    # Main user password
POSTGRES_DB=mydb                             # Default database
POSTGRES_REPLICATION_USER=replicator         # Replication user
POSTGRES_REPLICATION_PASSWORD=replicator123  # Replication password
```

## Troubleshooting

**Replica not connecting:**
- Check master logs: `./dc logs postgres-master`
- Check replica logs: `./dc logs postgres-replica`
- Verify healthcheck: `./dc ps`

**Replica stuck initializing:**
- Ensure master is fully healthy before starting replica
- Check network connectivity between containers
- Verify replication credentials in `.env.services`

**Reset replication:**
```bash
./dc down postgres-replica
docker volume rm resources_postgres-replica-data
./dc up -d postgres-replica
```
