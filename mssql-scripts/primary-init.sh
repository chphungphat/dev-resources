#!/bin/bash
set -e

# This script runs on MSSQL primary initialization
# It waits for SQL Server to start and then runs the setup script

echo "Waiting for SQL Server to start..."

# Wait for SQL Server to be ready
for i in {1..60}; do
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -Q "SELECT 1" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "SQL Server is ready!"
        break
    fi
    echo "SQL Server not ready yet, waiting... ($i/60)"
    sleep 2
done

# Check if we successfully connected
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -Q "SELECT 1" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: Could not connect to SQL Server after 120 seconds"
    exit 1
fi

# Run the setup script
echo "Running primary setup script..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -i /opt/mssql-scripts/primary-setup.sql

echo "Primary setup completed successfully!"
