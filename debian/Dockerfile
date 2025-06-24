# Use the official Debian slim image for a smaller base
FROM debian:bookworm-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl jq unzip ca-certificates iproute2 \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user and set up home directory
RUN useradd -m -d /home/container container
WORKDIR /home/container

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set permissions for the container user
RUN chown -R container:container /home/container

# Switch to non-root user
USER container

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
