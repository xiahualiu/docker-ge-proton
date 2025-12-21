#!/bin/bash

# Stop script on any error
set -e

echo "--- Ubuntu-based Proton Server ---"
echo "Proton Version: ${PROTON_VERSION}"

# 1. Update/Install Game via SteamCMD
# We use the variable STEAM_APP_ID provided in docker-compose
if [ -n "${STEAM_APP_ID}" ]; then
    echo "--- Checking for updates (App ID: ${STEAM_APP_ID}) ---"
    
    # SteamCMD command breakdown:
    # +login anonymous: Most dedicated servers allow anon login. If yours doesn't, you need to mount a config or pass credentials.
    # +app_update: Downloads the game
    ${STEAMCMD_DIR}/steamcmd.sh \
        +force_install_dir "${STEAM_APP_DIR}" \
        +login anonymous \
        +@sSteamCmdForcePlatformType windows \
        +app_update "${STEAM_APP_ID}" validate \
        +quit
else
    echo "!!! Warning: STEAM_APP_ID not set. Skipping Steam update. !!!"
fi

# 2. Validation check for the executable
if [ -z "${GAME_EXECUTABLE}" ]; then
    echo "ERROR: GAME_EXECUTABLE environment variable is missing."
    echo "Example: Binaries/Win64/Server.exe"
    exit 1
fi

# 3. Start Xvfb (Virtual Framebuffer)
# This creates a fake display :99 so Windows apps don't crash
echo "--- Starting Virtual Display (Xvfb) ---"
Xvfb :99 -screen 0 800x600x16 &
export DISPLAY=:99

# 4. Launch the Game
echo "--- Launching ${GAME_EXECUTABLE} ---"

# 'waitforexitandrun' is a Proton command that keeps the python script alive
# until the game executable closes.
exec "${PROTON_EXECUTABLE_PATH}" waitforexitandrun "${STEAM_APP_DIR}/${GAME_EXECUTABLE}" ${GAME_ARGS}