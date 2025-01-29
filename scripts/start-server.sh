#!/bin/bash
set -e  # Exit on error

# Function to log messages with timestamps
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Error handler
error_handler() {
    log_message "ERROR: An error occurred on line $1"
    exit 1
}

trap 'error_handler ${LINENO}' ERR

# Function to run SteamCMD commands
run_steamcmd() {
    local validate=$1
    local login_args="+login anonymous"
    
    if [ "${USERNAME}" != "" ]; then
        login_args="+login ${USERNAME} ${PASSWRD}"
    fi
    
    local validate_arg=""
    if [ "${validate}" == "true" ]; then
        validate_arg="validate"
    fi
    
    ${STEAMCMD_DIR}/steamcmd.sh \
        +@sSteamCmdForcePlatformType windows \
        +force_install_dir ${SERVER_DIR} \
        ${login_args} \
        +app_update ${GAME_ID} ${validate_arg} \
        +quit
}

# Check and install SteamCMD if necessary
if [ ! -f ${STEAMCMD_DIR}/steamcmd.sh ]; then
    log_message "SteamCMD not found! Downloading..."
    wget -q -O ${STEAMCMD_DIR}/steamcmd_linux.tar.gz http://media.steampowered.com/client/steamcmd_linux.tar.gz 
    tar --directory ${STEAMCMD_DIR} -xvzf ${STEAMCMD_DIR}/steamcmd_linux.tar.gz
    rm ${STEAMCMD_DIR}/steamcmd_linux.tar.gz
fi

# Update SteamCMD
log_message "Updating SteamCMD..."
run_steamcmd false

# Update Server
log_message "Updating Server..."
run_steamcmd ${VALIDATE}

# Prepare Wine environment
log_message "Preparing Wine environment..."
export WINEARCH=win64
export WINEPREFIX=${SERVER_DIR}/WINE64
export WINEDEBUG=warn+all
export ENABLE_VKBASALT=0
export WINE_VK_VULKAN_ONLY=1

# Check Wine directory
log_message "Checking Wine workdirectory..."
if [ ! -d ${SERVER_DIR}/WINE64 ]; then
    log_message "Wine workdirectory not found, creating..."
    mkdir -p ${SERVER_DIR}/WINE64
else
    log_message "Wine workdirectory found"
fi

# Initialize Wine if necessary
if [ ! -d ${SERVER_DIR}/WINE64/drive_c/windows ]; then
    log_message "Setting up Wine..."
    cd ${SERVER_DIR}
    timeout 30s winecfg > /dev/null 2>&1 || log_message "Warning: winecfg timed out, but this might be okay"
    sleep 5
else
    log_message "Wine is properly set up"
fi

# Create logs directory
mkdir -p ${SERVER_DIR}/logs

log_message "Starting server..."
cd ${SERVER_DIR}

# Wait for Wine to fully initialize
sleep 5

# Start the server with logging
log_message "Launching ASKA server..."
if ! xvfb-run --auto-servernum --server-args='-screen 0 640x480x24:32' \
    wine64 ${SERVER_DIR}/AskaServer.exe ${GAME_PARAMS} \
    > >(tee -a ${SERVER_DIR}/logs/server.log) \
    2> >(tee -a ${SERVER_DIR}/logs/error.log >&2); then
    
    log_message "Server crashed or failed to start. Check logs for details."
    exit 1
fi
