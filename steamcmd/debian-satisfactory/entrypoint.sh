#!/bin/bash

#
# Copyright (c) 2021 Matthew Penner
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

# Wait for the container to fully initialize
sleep 1

# Default the TZ environment variable to UTC.
TZ=${TZ:-UTC}
export TZ

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Switch to the container's working directory
cd /home/container || exit 1

# Set default values for steam if not provided
STEAM_USER=${STEAM_USER:-anonymous}
if [ "${STEAM_USER}" == "anonymous" ]; then
	STEAM_PASS=""
	STEAM_AUTH=""
fi

# --- Satisfactory Auto-Update Block ---
VERSION_FILE=".satisfactory_version"
CURRENT_VERSION=""
LATEST_VERSION=""

# Get the latest Satisfactory Dedicated Server version from Steam (using appid 1690800)
SRCDS_APPID=1690800

# Use steamcmd to get the latest buildid
LATEST_VERSION=$(./steamcmd/steamcmd.sh +login "${STEAM_USER}" "${STEAM_PASS}" "${STEAM_AUTH}" +app_info_update 1 +app_info_print ${SRCDS_APPID} +quit | grep -m 1 buildid | awk '{print $2}')

if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE")
fi

if [ "$CURRENT_VERSION" == "$LATEST_VERSION" ]; then
    echo "Satisfactory server is up to date (buildid $LATEST_VERSION). Skipping download."
else
    echo "Installing/Updating Satisfactory Dedicated Server (buildid $LATEST_VERSION)"
    ./steamcmd/steamcmd.sh +force_install_dir /home/container +login "${STEAM_USER}" "${STEAM_PASS}" "${STEAM_AUTH}" +app_update ${SRCDS_APPID} validate +quit
    echo "$LATEST_VERSION" > "$VERSION_FILE"
    echo "Satisfactory Dedicated Server install/update completed (buildid $LATEST_VERSION)"
fi
# --- End Satisfactory Auto-Update Block ---

# Replace Startup Variables
MODIFIED_STARTUP=$(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo -e ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
eval ${MODIFIED_STARTUP}