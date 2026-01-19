FROM postgres:17

# Copy the master init script into the image
COPY postgres-scripts/master-init.sh /docker-entrypoint-initdb.d/master-init.sh

# Ensure it's executable
RUN chmod +x /docker-entrypoint-initdb.d/master-init.sh
