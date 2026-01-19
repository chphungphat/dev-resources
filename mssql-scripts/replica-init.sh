#!/bin/bash
set -e

# This script runs on MSSQL replica initialization
# It waits for SQL Server to start and then configures as subscriber

echo "Waiting for SQL Server to start..."

# Wait for local SQL Server to be ready
for i in {1..60}; do
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -Q "SELECT 1" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Local SQL Server is ready!"
        break
    fi
    echo "Local SQL Server not ready yet, waiting... ($i/60)"
    sleep 2
done

# Check if we successfully connected
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -Q "SELECT 1" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: Could not connect to local SQL Server after 120 seconds"
    exit 1
fi

# Wait for primary SQL Server to be ready
echo "Waiting for primary SQL Server to be ready..."
for i in {1..90}; do
    /opt/mssql-tools18/bin/sqlcmd -S "$MSSQL_PRIMARY_HOST" -U sa -P "$MSSQL_SA_PASSWORD" -C -Q "SELECT 1" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Primary SQL Server is ready!"
        break
    fi
    echo "Primary SQL Server not ready yet, waiting... ($i/90)"
    sleep 2
done

# Additional wait for primary to complete its setup
echo "Waiting additional 10 seconds for primary setup to complete..."
sleep 10

# Run the replica setup script
echo "Running replica setup script..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -i /opt/mssql-scripts/replica-setup.sql

echo "Replica setup completed successfully!"
