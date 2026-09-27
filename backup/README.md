# Fallout 4 Save Backups (Steam + Proton)

> **STATUS: TESTING — YMMV.** Smoke-tested against fake prefixes (default and
> second-drive Steam libraries); run one manual backup and inspect it before
> trusting the timer.

Same design as `morrowind-cg3d/backup`: hardlink-deduplicated snapshots of the
saves, mirrored to a NAS if configured, on a daily systemd user timer. Each
snapshot also captures the three INIs and `plugins.txt`, because a modded
save is only restorable against the load order it was made with.

## What it does

- Locates the Proton prefix (`steamapps/compatdata/377160/pfx`) in any Steam
  library listed in `libraryfolders.vdf` (game on the 4 TB NVMe works).
- Snapshots `.../Documents/My Games/Fallout4/Saves/` (`.fos` + F4SE `.f4se`
  co-saves) into `~/mods/fallout4/saves_backup_local/<timestamp>/saves/`.
- Copies `Fallout4.ini`, `Fallout4Prefs.ini`, `Fallout4Custom.ini`, `plugins.txt`
  into the snapshot's `config/`.
- `latest` symlink, prune to 30 snapshots, `flock` guard, quiet exit when
  there are no saves yet.

## Setup

```bash
cat > ~/.config/fo4-backup.conf <<'EOF'
NAS_DEST="user@nas.local:/volume1/backups/fallout4"   # optional; dedicated dir (mirrors with --delete)
# KEEP_SNAPSHOTS=60
# STEAM_ROOT="$HOME/.local/share/Steam"               # only if auto-detection fails
EOF
~/mods/fallout4/backup/backup_fo4_saves.sh
mkdir -p ~/.config/systemd/user
cp ~/mods/fallout4/backup/fo4-backup.{service,timer} ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now fo4-backup.timer
systemctl --user list-timers fo4-backup.timer
```

## Restoring

```bash
PFX=<library>/steamapps/compatdata/377160/pfx
rsync -a ~/mods/fallout4/saves_backup_local/latest/saves/ \
         "$PFX/drive_c/users/steamuser/Documents/My Games/Fallout4/Saves/"
```

Restore `plugins.txt` from the snapshot's `config/` if the save complains
about missing plugins.

## Steam Cloud

Turn it **off** for Fallout 4. Modded saves exceed the cloud quota (older saves
get silently dropped), and a fresh Proton prefix can overwrite the cloud save
with a blank one on first launch. This timer is the backup; the cloud is not.
