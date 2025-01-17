#!/bin/bash

DATA_DIR="${DATA_DIR:-/data}"
ARCHIVEBOX_USER="${ARCHIVEBOX_USER:-archivebox}"


# Set the archivebox user UID & GID
if [[ -n "$PUID" && "$PUID" != 0 ]]; then
    usermod -u "$PUID" "$ARCHIVEBOX_USER" > /dev/null 2>&1
fi
if [[ -n "$PGID" && "$PGID" != 0 ]]; then
    groupmod -g "$PGID" "$ARCHIVEBOX_USER" > /dev/null 2>&1
fi

export PUID="$(id -u archivebox)"
export PGID="$(id -g archivebox)"

# Check the permissions of the data dir (or create if it doesn't exist)
if [[ -d "$DATA_DIR/archive" ]]; then
    if touch "$DATA_DIR/archive/.permissions_test_safe_to_delete"; then
        # It's fine, we are able to write to the data directory
        rm "$DATA_DIR/archive/.permissions_test_safe_to_delete"
        # echo "[√] Permissions are correct"
    else
        echo "[X] Permissions Error: ArchiveBox is not able to write to your data dir. You need to fix the data dir ownership and retry:" >2
        echo "    chown -R $PUID:$PGID data" >2
        echo "    https://docs.linuxserver.io/general/understanding-puid-and-pgid" >2
        exit 1
    fi
else
    # create data directory
    mkdir -p "$DATA_DIR/logs"
fi
chown $ARCHIVEBOX_USER:$ARCHIVEBOX_USER "$DATA_DIR" "$DATA_DIR"/*

# Drop permissions to run commands as the archivebox user
if [[ "$1" == /* || "$1" == "echo" || "$1" == "archivebox" ]]; then
    # arg 1 is a binary, execute it verbatim
    # e.g. "archivebox init"
    #      "/bin/bash"
    #      "echo"
    exec gosu "$ARCHIVEBOX_USER" bash -c "$*"
else
    # no command given, assume args were meant to be passed to archivebox cmd
    # e.g. "add https://example.com"
    #      "manage createsupseruser"
    #      "server 0.0.0.0:8000"
    exec gosu "$ARCHIVEBOX_USER" bash -c "archivebox $*"
fi
