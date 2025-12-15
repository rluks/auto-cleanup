#!/bin/bash
set -euo pipefail

DAYS=30

echo "Starting trash cleanup (files older than $DAYS days)"

# Clean primary trash
if [[ -d "$HOME/.local/share/Trash" ]]; then
    echo "Cleaning primary trash..."
    find "$HOME/.local/share/Trash/files" "$HOME/.local/share/Trash/info" \
         -type f -mtime +$DAYS -delete
    
    find "$HOME/.local/share/Trash/files" "$HOME/.local/share/Trash/info" \
         -type d -empty -delete || true
fi

# Clean external drives
for mount_base in /media/$USER /mnt; do
    if [[ -d "$mount_base" ]]; then
        for trash_dir in "$mount_base"/*/\.Trash-*; do
            if [[ -d "$trash_dir" ]]; then
                echo "Processing: $trash_dir"
                
                find "$trash_dir/files" "$trash_dir/info" \
                     -type f -mtime +$DAYS -delete || true
                
                find "$trash_dir/files" "$trash_dir/info" \
                     -type d -empty -delete || true
            fi
        done
    fi
done

echo "Cleanup complete"
