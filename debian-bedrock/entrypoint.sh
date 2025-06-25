#!/bin/bash
cd /home/container

# Make internal Docker IP address available to processes.
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# --- Minecraft Bedrock Auto-Update Block ---
if [ -z "${AUTO_UPDATE}" ] || [ "${AUTO_UPDATE}" == "1" ]; then
    BEDROCK_VERSION=${BEDROCK_VERSION:-latest}
    DOWNLOAD_FILE="bedrock-server-installer.zip"
    RANDVERSION=$(echo $((1 + $RANDOM % 4000)))
    VERSION_FILE=".bedrock_version"
    CURRENT_VERSION=""
    LATEST_VERSION=""

    if [ "${BEDROCK_VERSION}" == "latest" ]; then
        echo "Finding latest Bedrock server version"
        DOWNLOAD_URL=$(curl --silent https://net-secondary.web.minecraft-services.net/api/v1.0/download/links | jq -r '.result.links[] | select(.downloadType == "serverBedrockLinux") | .downloadUrl')
        LATEST_VERSION=$(basename "$DOWNLOAD_URL" | sed -E 's/bedrock-server-([0-9.]+)\.zip/\1/')
        if [ -z "${DOWNLOAD_URL}" ] || [ -z "$LATEST_VERSION" ]; then
            echo "Failed to retrieve the latest Bedrock server version. Please check your network connection or the Minecraft API."
            exit 1
        fi
    else
        echo "Downloading ${BEDROCK_VERSION} Bedrock server"
        DOWNLOAD_URL=https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-$BEDROCK_VERSION.zip
        LATEST_VERSION="$BEDROCK_VERSION"
    fi

    if [ -f "$VERSION_FILE" ]; then
        CURRENT_VERSION=$(cat "$VERSION_FILE")
    fi

    if [ "$CURRENT_VERSION" == "$LATEST_VERSION" ]; then
        echo "Bedrock server is up to date (version $LATEST_VERSION). Skipping download."
    else
        echo "Download URL: $DOWNLOAD_URL"
        echo -e "Backing up config files"
        mkdir -p /tmp/config_backup
        cp server.properties /tmp/config_backup/ 2>/dev/null
        cp permissions.json /tmp/config_backup/ 2>/dev/null
        cp allowlist.json /tmp/config_backup/ 2>/dev/null

        echo -e "Downloading files from: $DOWNLOAD_URL"
        curl --progress-bar -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.$RANDVERSION.212 Safari/537.36" -H "Accept-Language: en" -o $DOWNLOAD_FILE $DOWNLOAD_URL

        echo -e "Unpacking server files..."
        unzip -o -q $DOWNLOAD_FILE

        echo -e "Cleaning up after installing"
        rm $DOWNLOAD_FILE

        echo -e "Restoring backup config files..."
        cp -rf /tmp/config_backup/* /home/container/ 2>/dev/null || echo "No files to restore"

        chmod +x bedrock_server

        echo "$LATEST_VERSION" > "$VERSION_FILE"
        echo -e "Bedrock auto-update completed (updated to $LATEST_VERSION)"
    fi
fi
# --- End Bedrock Auto-Update Block ---

# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo -e ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
eval ${MODIFIED_STARTUP}