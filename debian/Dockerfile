# Use the official Debian slim image for a smaller base
FROM debian:bookworm-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV USER=container HOME=/home/container

# Create a non-root user and set up home directory
RUN useradd -m -d /home/container -s /bin/bash container \
    && ln -s /home/container/ /nonexistent

## Update base packages
RUN apt update \
    && apt upgrade -y \
    && apt install -y gcc g++ libgcc-12-dev libc++-dev gdb libc6 git wget curl tar zip unzip binutils xz-utils liblzo2-2 cabextract iproute2 net-tools netcat-traditional telnet libatomic1 libsdl1.2debian libsdl2-2.0-0 \
        libfontconfig1 icu-devtools libunwind8 libssl-dev sqlite3 libsqlite3-dev libmariadb-dev-compat libduktape207 locales ffmpeg gnupg2 apt-transport-https software-properties-common ca-certificates \
        liblua5.3-0 libz3-dev libzadc4 rapidjson-dev tzdata libevent-dev libzip4 libprotobuf32 libfluidsynth3 procps libstdc++6 tini \
    && rm -rf /var/lib/apt/lists/*

## Configure locale
RUN update-locale lang=en_US.UTF-8 \
    && dpkg-reconfigure --frontend noninteractive locales

WORKDIR /home/container

# Copy entrypoint script and set permissions
COPY --chown=container:container entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set permissions for the container user
RUN chown -R container:container /home/container

# Switch to non-root user
USER container

STOPSIGNAL SIGINT

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/entrypoint.sh"]
