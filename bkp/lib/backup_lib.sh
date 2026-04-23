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

create_snapshot() {
    local base="$1"          # e.g. /mnt/bkp_01_01/@
    local snap_dir="$2"      # e.g. /mnt/bkp_01_01/@.snapshots
    local name="$3"          # e.g. 2026-01-01_12-00-00

    local target="$snap_dir/$name"

    mkdir -p "$snap_dir"

    echo "# Creating snapshot: $target"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        echo "DRY RUN: btrfs subvolume snapshot -r $base $target"
        return 0
    fi

    btrfs subvolume snapshot -r "$base" "$target"
}

check_snapshot_age() {
    local snap_dir="$1"
    local max_age_days="$2"

    find "$snap_dir" \
        -mindepth 1 -maxdepth 1 \
        -type d \
        -mtime +"$max_age_days" \
        -print \
        | while read -r snap; do
            echo "OLD SNAPSHOT: $snap"
        done
}
