#!/usr/bin/env bash

setup_rsync() {
    RSYNC=(rsync -aAXHv --info=progress2,stats --delete --numeric-ids --exclude='lost+found/')
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        echo "DRY RUN MODE (no changes will be made)"
        RSYNC+=(--dry-run)
    fi
}

setup_logging() {
    local name="$1"
    local date="$2"
    mkdir -p /var/log/bkp
    LOG_FILE="/var/log/bkp/${name}_${date}.log"
    exec > >(tee -a "$LOG_FILE") 2>&1
    echo "# $name started at $date"
}

check_mounts() {
    for d in "$@"; do
        mountpoint -q "$d" || { echo "ERROR: $d not mounted"; exit 1; }
    done
}

setup_lock() {
    exec 9>"/tmp/bkp.lock"  # same lock file for all backup operations
    flock -n 9 || { echo "Another backup/mirror operation is running"; exit 1; }
}
