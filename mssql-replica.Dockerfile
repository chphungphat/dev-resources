FROM mcr.microsoft.com/mssql/server:2022-latest

USER root

# Install required tools
RUN apt-get update && apt-get install -y \
    curl \
    apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# Copy the replica init scripts
COPY mssql-scripts/replica-init.sh /opt/mssql-scripts/replica-init.sh
COPY mssql-scripts/replica-setup.sql /opt/mssql-scripts/replica-setup.sql

# Ensure scripts are executable
RUN chmod +x /opt/mssql-scripts/replica-init.sh

USER mssql

# Run SQL Server and initialization script
CMD /bin/bash -c "/opt/mssql-scripts/replica-init.sh & /opt/mssql/bin/sqlservr"
