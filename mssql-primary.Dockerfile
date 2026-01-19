FROM mcr.microsoft.com/mssql/server:2022-latest

USER root

# Install required tools
RUN apt-get update && apt-get install -y \
    curl \
    apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# Copy the primary init scripts
COPY mssql-scripts/primary-init.sh /opt/mssql-scripts/primary-init.sh
COPY mssql-scripts/primary-setup.sql /opt/mssql-scripts/primary-setup.sql

# Ensure scripts are executable
RUN chmod +x /opt/mssql-scripts/primary-init.sh

USER mssql

# Run SQL Server and initialization script
CMD /bin/bash -c "/opt/mssql-scripts/primary-init.sh & /opt/mssql/bin/sqlservr"
