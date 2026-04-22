#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

setup_logging() {
    local name="$1"
    local date="$2"
    LOG_FILE="/tmp/${name}_${date}.log"
    exec > >(tee -a "$LOG_FILE") 2>&1
    echo "# $name started at $date"
}

check_mounts() {
    for d in "$@"; do
        mountpoint -q "$d" || { echo "ERROR: $d not mounted"; exit 1; }
    done
}

setup_lock() {
    local name="$1"
    exec 9>"/tmp/${name}.lock"
    flock -n 9 || { echo "Another $name is running"; exit 1; }
}

run_check_disks_health() {
    "$SCRIPT_DIR/check_disks_health"
}
