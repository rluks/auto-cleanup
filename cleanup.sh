#!/bin/bash
set -euo pipefail

DAYS=30

echo "Starting trash cleanup (files older than $DAYS days)"

# Remove every entry of one Trash folder that was trashed more than $DAYS days
# ago, along with its .trashinfo. Age comes from the .trashinfo, which is
# written when the file is trashed. The trashed file itself keeps its old
# mtime, so aging by it deleted an old file the same night it was trashed.
purge_trash() {
    local trash="$1" info name
    [[ -d "$trash/info" ]] || return 0
    find "$trash/info" -maxdepth 1 -type f -name '*.trashinfo' -mtime +$DAYS -print0 |
    while IFS= read -r -d '' info; do
        name=$(basename -- "$info" .trashinfo)
        [[ -n $name && $name != . && $name != .. && $name != *.trashinfo ]] || continue
        rm -rf -- "$trash/files/$name"
        rm -f -- "$info"
    done
}

# Clean primary trash
if [[ -d "$HOME/.local/share/Trash" ]]; then
    echo "Cleaning primary trash..."
    purge_trash "$HOME/.local/share/Trash"
fi

# Clean external drives
for mount_base in /media/$USER /mnt; do
    if [[ -d "$mount_base" ]]; then
        for trash_dir in "$mount_base"/*/\.Trash-*; do
            if [[ -d "$trash_dir" ]]; then
                echo "Processing: $trash_dir"
                
                purge_trash "$trash_dir" || true
            fi
        done
    fi
done

echo "Pruning Obsidian backups (grandfather-father-son retention)..."
"$(dirname "$0")/obsidian-backup-prune.sh"

echo "Cleanup complete"
