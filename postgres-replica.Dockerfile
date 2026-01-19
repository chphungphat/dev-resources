FROM postgres:17

# Copy the replica init script into the image
COPY postgres-scripts/replica-init.sh /replica-init.sh

# Ensure it's executable
RUN chmod +x /replica-init.sh
