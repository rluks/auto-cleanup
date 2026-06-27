#!/bin/bash
set -euo pipefail

# Keeps a grandfather-father-son rotation of Obsidian local-backup zips:
#   the 3 most recent distinct days, 3 most recent distinct weeks, and
#   3 most recent distinct months each keep their latest backup. Everything
# else gets deleted. Run with --dry-run to preview without deleting.

BACKUP_DIR="/home/roman/Documents/Obsidian"
NAME_PATTERN="Backup-*.zip"
KEEP_DAILY=3
KEEP_WEEKLY=3
KEEP_MONTHLY=3
DRY_RUN=0

if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
fi

shopt -s nullglob
files=("$BACKUP_DIR"/$NAME_PATTERN)
shopt -u nullglob

if [[ ${#files[@]} -eq 0 ]]; then
    echo "No backups matching $NAME_PATTERN in $BACKUP_DIR"
    exit 0
fi

# Filenames are Backup-YYYY_MM_DD-HH_MM_SS.zip, which sorts lexicographically
# in chronological order, so a plain reverse sort gives newest-first.
mapfile -t sorted < <(printf '%s\n' "${files[@]}" | sort -r)

declare -A seen_day seen_week seen_month
declare -A keep_set
day_count=0 week_count=0 month_count=0

for f in "${sorted[@]}"; do
    base=$(basename "$f")
    if [[ ! $base =~ Backup-([0-9]{4})_([0-9]{2})_([0-9]{2})-([0-9]{2})_([0-9]{2})_([0-9]{2}) ]]; then
        continue
    fi
    y=${BASH_REMATCH[1]} m=${BASH_REMATCH[2]} d=${BASH_REMATCH[3]}
    day_key="$y$m$d"
    month_key="$y$m"
    week_key=$(date -d "${y}-${m}-${d}" +%G-%V)

    keep_this=0
    if [[ -z "${seen_day[$day_key]:-}" && $day_count -lt $KEEP_DAILY ]]; then
        seen_day[$day_key]=1
        day_count=$((day_count + 1))
        keep_this=1
    fi
    if [[ -z "${seen_week[$week_key]:-}" && $week_count -lt $KEEP_WEEKLY ]]; then
        seen_week[$week_key]=1
        week_count=$((week_count + 1))
        keep_this=1
    fi
    if [[ -z "${seen_month[$month_key]:-}" && $month_count -lt $KEEP_MONTHLY ]]; then
        seen_month[$month_key]=1
        month_count=$((month_count + 1))
        keep_this=1
    fi

    if [[ $keep_this -eq 1 ]]; then
        keep_set["$f"]=1
    fi
done

freed=0
for f in "${sorted[@]}"; do
    if [[ -z "${keep_set[$f]:-}" ]]; then
        size=$(stat -c %s "$f")
        freed=$((freed + size))
        if [[ $DRY_RUN -eq 1 ]]; then
            echo "Would delete: $f"
        else
            echo "Deleting: $f"
            rm -f "$f"
        fi
    else
        echo "Keeping:  $f"
    fi
done

echo "Total $( [[ $DRY_RUN -eq 1 ]] && echo "would free" || echo "freed" ): $((freed / 1024 / 1024)) MB"
