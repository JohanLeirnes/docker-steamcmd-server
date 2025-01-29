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

# Create necessary directories
mkdir -p ${SERVER_DIR}/logs
mkdir -p ${SERVER_DIR}/saves/server

# Function to update a specific property in the server properties file
update_property() {
    local property="$1"
    local value="$2"
    local file="${SERVER_DIR}/server properties.txt"
    
    # Check if file exists
    if [ ! -f "$file" ]; then
        log_message "ERROR: server properties.txt not found!"
        return 1
    fi  
    
    # Check if property exists and update it
    if grep -q "^${property} = " "$file"; then
        # Get current value
        current_value=$(grep "^${property} = " "$file" | sed "s|^${property} = ||")
        
        # Only update if value is different
        if [ "$current_value" != "$value" ]; then
            # Create a temporary file
            TMP_FILE=$(mktemp)
            # Replace the line containing the property
            sed "s|^${property} = .*|${property} = ${value}|" "$file" > "$TMP_FILE"
            # Move temporary file back to original
            mv "$TMP_FILE" "$file"
            log_message "Updated ${property} from ${current_value} to ${value}"
        else
            log_message "${property} already set to ${value}, skipping"
        fi
    else
        log_message "WARNING: Property ${property} not found in configuration file"
    fi
}

# Update server properties if environment variables are set
log_message "Updating server properties..."

update_property "display name" "${SERVER_NAME:-Docker ASKA Server}"
update_property "server name" "${SERVER_NAME:-Docker ASKA Server}"
update_property "password" "${SERVER_PASSWORD:-}"
update_property "steam game port" "${GAME_PORT:-27015}"
update_property "steam query port" "${QUERY_PORT:-27016}"
update_property "authentication token" "${AUTH_TOKEN:-}"  # This should be required
update_property "region" "${SERVER_REGION:-default}"
update_property "keep server world alive" "${KEEP_ALIVE:-false}"
update_property "autosave style" "${AUTOSAVE_STYLE:-every morning}"
update_property "mode" "${GAME_MODE:-normal}"

# Check and install SteamCMD if necessary
if [ ! -f ${STEAMCMD_DIR}/steamcmd.sh ]; then
    log_message "SteamCMD not found! Downloading..."
    wget -q -O ${STEAMCMD_DIR}/steamcmd_linux.tar.gz http://media.steampowered.com/client/steamcmd_linux.tar.gz 
    tar --directory ${STEAMCMD_DIR} -xvzf ${STEAMCMD_DIR}/steamcmd_linux.tar.gz
    rm ${STEAMCMD_DIR}/steamcmd_linux.tar.gz
fi

# Update SteamCMD and Server
log_message "Updating SteamCMD and Server..."
${STEAMCMD_DIR}/steamcmd.sh \
    +@sSteamCmdForcePlatformType windows \
    +force_install_dir ${SERVER_DIR} \
    +login anonymous \
    +app_update ${GAME_ID} ${VALIDATE:+validate} \
    +quit

# Wine configuration
export WINEARCH=win64
export WINEPREFIX=${SERVER_DIR}/WINE64
export WINEDEBUG=fixme-all,err+all,warn+module,warn+file
export STAGING_SHARED_MEMORY=1
export WINE_LARGE_ADDRESS_AWARE=1
export WINEDLLOVERRIDES="mscoree,mshtml="

# Create Wine prefix if it doesn't exist
if [ ! -d ${SERVER_DIR}/WINE64 ]; then
    log_message "Creating new Wine prefix..."
    wineboot --init
    sleep 10
    
    # Configure Wine
    log_message "Configuring Wine..."
    winecfg /v win10
    
    # Install Visual C++ Redistributables
    log_message "Installing Visual C++ Redistributables..."
    wget -q -O ${SERVER_DIR}/vcredist_x64.exe https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe
    wine ${SERVER_DIR}/vcredist_x64.exe /quiet
    sleep 5
    rm ${SERVER_DIR}/vcredist_x64.exe
fi

# Pre-launch checks
log_message "Checking server files..."
if [ ! -f ${SERVER_DIR}/AskaServer.exe ]; then
    log_message "ERROR: AskaServer.exe not found!"
    exit 1
fi

# Configure Windows version for Wine
winetricks win10

# Create symbolic links for required directories
ln -sf ${SERVER_DIR} Z:/serverdata
ln -sf ${SERVER_DIR}/saves Z:/saves

# Set up Virtual Desktop
export DISPLAY=:0
Xvfb :0 -screen 0 640x480x24:32 &
sleep 2

# Debug information
log_message "Server directory contents:"
ls -la ${SERVER_DIR}

# Launch the server
log_message "Launching ASKA server..."
cd ${SERVER_DIR}

LAUNCH_CMD="wine64 AskaServer.exe \
    -batchmode \
    -nographics \
    -propertiesPath \"${SERVER_DIR}/server properties.txt\" \
    -logFile \"${SERVER_DIR}/logs/unity_detailed.log\" \
    ${GAME_PARAMS}"

# Execute with proper error handling and separate logs
eval $LAUNCH_CMD \
    > >(tee -a ${SERVER_DIR}/logs/server.log) \
    2> >(tee -a ${SERVER_DIR}/logs/error.log >&2)

# Monitor the server process
SERVER_PID=$!
wait $SERVER_PID
