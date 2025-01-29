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

log_message "Ensuring UID: ${UID} matches user"
usermod -u ${UID} ${USER}

log_message "Ensuring GID: ${GID} matches user"
groupmod -g ${GID} ${USER} > /dev/null 2>&1 ||:
usermod -g ${GID} ${USER}

log_message "Setting umask to ${UMASK}"
umask ${UMASK}

log_message "Checking for optional scripts"
cp -f /opt/custom/user.sh /opt/scripts/start-user.sh > /dev/null 2>&1 ||:
cp -f /opt/scripts/user.sh /opt/scripts/start-user.sh > /dev/null 2>&1 ||:

if [ -f /opt/scripts/start-user.sh ]; then
    log_message "Found optional script, executing"
    chmod -f +x /opt/scripts/start-user.sh ||:
    if ! /opt/scripts/start-user.sh; then
        log_message "Optional Script has thrown an Error"
    fi
else
    log_message "No optional script found, continuing"
fi

log_message "Taking ownership of data..."
chown -R root:${GID} /opt/scripts
chmod -R 750 /opt/scripts
chown -R ${UID}:${GID} ${DATA_DIR}

log_message "Starting server..."
term_handler() {
    log_message "Received SIGTERM, shutting down..."
    kill -SIGTERM "$killpid"
    wait "$killpid" -f 2>/dev/null
    exit 143;
}

trap 'kill ${!}; term_handler' SIGTERM
su ${USER} -c "/opt/scripts/start-server.sh" &
killpid="$!"
while true
do
    wait $killpid
    exit 0;
done
