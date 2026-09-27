#!/bin/bash
set -euo pipefail

# Fallout 4 (Steam + Proton) save backup — local hardlink-deduplicated snapshots
# + optional NAS sync. Same design as morrowind-cg3d/backup, pointed at the
# Proton prefix. Run by hand or from the systemd timer in this directory.
#
# Snapshots use rsync --link-dest against the previous snapshot, so daily
# backups of unchanged saves cost almost no disk. The three INI files and
# plugins.txt are captured alongside each snapshot: a save is only as good as
# the load order it was made with.
#
# Override any default below in ~/.config/fo4-backup.conf (plain bash, sourced
# if present) — keeps NAS hostnames/paths out of the git repo, e.g.:
#   NAS_DEST="user@nas.local:/volume1/backups/fallout4"
#   KEEP_SNAPSHOTS=60
#   STEAM_ROOT="$HOME/.local/share/Steam"

APPID=377160
# Steam library roots to probe for the Proton prefix (first hit wins)
STEAM_ROOTS=("$HOME/.steam/steam" "$HOME/.local/share/Steam" "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam")
STEAM_ROOT=""
BACKUP_ROOT="$HOME/mods/fallout4/saves_backup_local"
NAS_DEST=""            # empty = skip NAS sync. MUST be a dedicated directory:
                       # the sync mirrors with --delete.
KEEP_SNAPSHOTS=30
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/fo4-backup.lock"

CONF="$HOME/.config/fo4-backup.conf"
# shellcheck source=/dev/null
[[ -f "$CONF" ]] && source "$CONF"

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "Another backup is already running — exiting."
    exit 0
fi

command -v rsync >/dev/null 2>&1 || { echo "ERROR: rsync not found." >&2; exit 1; }

# Locate the Proton prefix. Steam libraries on other drives are listed in
# libraryfolders.vdf; compatdata always lives in the library that owns the game.
find_prefix() {
    local roots=("${STEAM_ROOTS[@]}")
    [[ -n "$STEAM_ROOT" ]] && roots=("$STEAM_ROOT" "${roots[@]}")
    local r vdf lib
    for r in "${roots[@]}"; do
        [[ -d "$r/steamapps/compatdata/$APPID/pfx" ]] && { echo "$r/steamapps/compatdata/$APPID/pfx"; return; }
        vdf="$r/steamapps/libraryfolders.vdf"
        [[ -f "$vdf" ]] || continue
        while IFS= read -r lib; do
            [[ -d "$lib/steamapps/compatdata/$APPID/pfx" ]] && { echo "$lib/steamapps/compatdata/$APPID/pfx"; return; }
        done < <(grep -oP '"path"\s+"\K[^"]+' "$vdf")
    done
}
PFX=$(find_prefix || true)
if [[ -z "$PFX" ]]; then
    echo "ERROR: could not find the Fallout 4 Proton prefix (compatdata/$APPID). Set STEAM_ROOT in $CONF." >&2
    exit 1
fi
MYGAMES="$PFX/drive_c/users/steamuser/Documents/My Games/Fallout4"
SAVES_DIR="$MYGAMES/Saves"
PLUGINS_TXT="$PFX/drive_c/users/steamuser/AppData/Local/Fallout4/plugins.txt"

if [[ ! -d "$SAVES_DIR" ]] || \
   [[ -z "$(find "$SAVES_DIR" -mindepth 1 -name '*.fos' -print -quit 2>/dev/null)" ]]; then
    echo "No saves found in $SAVES_DIR — nothing to back up."
    exit 0
fi

STAMP=$(date +%Y%m%d-%H%M%S)
SNAP_DIR="$BACKUP_ROOT/$STAMP"
mkdir -p "$SNAP_DIR"

LINK_DEST=()
if [[ -d "$BACKUP_ROOT/latest/saves" ]]; then
    LINK_DEST=(--link-dest="$BACKUP_ROOT/latest/saves")
fi

echo "Backing up saves -> $SNAP_DIR"
rsync -a "${LINK_DEST[@]}" "$SAVES_DIR"/ "$SNAP_DIR/saves"/

mkdir -p "$SNAP_DIR/config"
for f in Fallout4.ini Fallout4Prefs.ini Fallout4Custom.ini; do
    [[ -f "$MYGAMES/$f" ]] && cp -a "$MYGAMES/$f" "$SNAP_DIR/config/"
done
[[ -f "$PLUGINS_TXT" ]] && cp -a "$PLUGINS_TXT" "$SNAP_DIR/config/"
# F4SE co-save data lives inside Saves/ (*.f4se) and is already included above.

ln -sfn "$SNAP_DIR" "$BACKUP_ROOT/latest"

mapfile -t SNAPSHOTS < <(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -name '20*' | sort)
COUNT=${#SNAPSHOTS[@]}
if (( COUNT > KEEP_SNAPSHOTS )); then
    echo "Pruning to newest $KEEP_SNAPSHOTS snapshots..."
    for old in "${SNAPSHOTS[@]:0:COUNT-KEEP_SNAPSHOTS}"; do
        echo "  removing $old"
        rm -rf "$old"
    done
fi

if [[ -n "$NAS_DEST" ]]; then
    echo "Syncing to NAS: $NAS_DEST"
    if rsync -azH --delete "$BACKUP_ROOT"/ "$NAS_DEST"/; then
        echo "NAS sync OK."
    else
        echo "WARNING: NAS sync failed (rsync exit $?) — local snapshot is intact." >&2
        exit 2
    fi
fi

echo "Backup complete: $SNAP_DIR"
