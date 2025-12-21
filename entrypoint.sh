#!/bin/bash

# Stop script on any error
set -e

echo "--- Ubuntu-based Proton Server ---"
echo "Proton Version: ${PROTON_VERSION}"

# Update/Install Game via SteamCMD
# We use the variable STEAM_APP_ID provided in docker-compose
if [ -n "${STEAM_APP_ID}" ]; then
    # SteamCMD command breakdown:
    # +login anonymous: Most dedicated servers allow anon login. If yours doesn't, you need to mount a config or pass credentials.
    # +app_update: Downloads the game
    echo "--- Checking for updates (App ID: ${STEAM_APP_ID}) ---"
    ${STEAMCMD_DIR}/steamcmd.sh \
        +force_install_dir "${STEAM_APP_DIR}" \
        +login anonymous \
        +@sSteamCmdForcePlatformType windows \
        +app_update "${STEAM_APP_ID}" validate \
        +quit
else
    echo "!!! Warning: STEAM_APP_ID not set. Skipping Steam update. !!!"
    exit 1
fi

# Validation check for the executable
if [ -z "${GAME_EXECUTABLE}" ]; then
    echo "ERROR: GAME_EXECUTABLE environment variable is missing."
    echo "Example: Binaries/Win64/Server.exe"
    exit 1
fi

# # Start Xvfb (Virtual Framebuffer) (Optional)
# # This creates a fake display :99 so Windows apps don't crash
# echo "--- Starting Virtual Display (Xvfb) ---"
# Xvfb :99 -screen 0 800x600x16 &
# export DISPLAY=:99

# Launch the Game
echo "--- Launching ${STEAM_APP_DIR}/${GAME_EXECUTABLE} ---"

# Check if the game executable exists
if [ ! -f "${STEAM_APP_DIR}/${GAME_EXECUTABLE}" ]; then
    echo "ERROR: Game executable not found at ${STEAM_APP_DIR}/${GAME_EXECUTABLE}"
    exit 1
fi

# Set Proton related environment variables
export STEAM_COMPAT_CLIENT_INSTALL_PATH="${STEAMCMD_DIR}"
export STEAM_COMPAT_DATA_PATH="${STEAMCMD_DIR}/compatdata/${STEAM_APP_ID}"

# Make sure compatibility data path exists for Proton
mkdir -p "${STEAM_COMPAT_DATA_PATH}"

# Keeps the Proton alive until the game executable closes.
"${PROTON_EXECUTABLE_PATH}" waitforexitandrun "${STEAM_APP_DIR}/${GAME_EXECUTABLE}" ${GAME_ARGS}