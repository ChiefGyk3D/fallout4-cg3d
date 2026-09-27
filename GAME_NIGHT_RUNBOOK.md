# Fallout 4 Game Night Runbook

> **STATUS: TESTING — YMMV.** First-run runbook. Nothing here has run on the
> real machine yet; expect to fix a few archive layouts in `extract_mods.sh`
> on prep night (send the extractor's NOTES/ISSUES block back and they get
> pinned). Hardware: Ryzen 9 5950X · 64 GB · RTX 5070 Ti · Pop!_OS · Steam.

**Two sessions.** Prep night (~2.5 h, mostly downloads) builds and validates;
game night plays a fresh character on a finished build.

---

## Session A — Prep Night

### A1. Steam side (10 min, before anything else)

1. Steam → Fallout 4 → Properties:
   - **Compatibility** → force **Proton 11.0-2** (GE-Proton11-7 is the fallback)
   - **DLC** → uncheck **High Resolution Texture Pack** (58 GB, no gain, hurts perf)
   - **General** → Steam Cloud **off** for this game
   - **Updates** → "Only update this game when I launch it"
2. Launch the game **once** through the vanilla launcher (generates the INIs,
   "Detecting video hardware"). Reach the main menu, quit. Never use the
   launcher again after this: it rewrites `Fallout4Prefs.ini`.
3. Confirm the driver:
   ```bash
   nvidia-smi --query-gpu=driver_version --format=csv,noheader   # 570+
   cat /proc/driver/nvidia/version                              # must say Open Kernel Module
   ```

### A2. Repo + backups (5 min)

```bash
mkdir -p ~/mods && cd ~/mods
git clone https://github.com/ChiefGyk3D/fallout4-cg3d fallout4 && cd fallout4
mkdir -p mod_files
mkdir -p ~/.config/systemd/user
cp backup/fo4-backup.{service,timer} ~/.config/systemd/user/
systemctl --user daemon-reload && systemctl --user enable --now fo4-backup.timer
./backup/backup_fo4_saves.sh          # snapshot of the (probably empty) prefix; also proves it found the prefix
```

NAS mirror: `~/.config/fo4-backup.conf` with `NAS_DEST=` (see `backup/README.md`).

### A3. Downloads (~60 min)

All into `~/mods/fallout4/mod_files/`, **Nexus filenames kept**. Log in to
Nexus first; one tab at a time (Nexus rate-limits by IP).

**Required (Tier 1)** — every row in `mod-list.txt` marked Tier 1, in short:

| # | Mod | Link |
|---|-----|------|
| 1 | **F4SE 0.7.9** (`f4se_0_07_09.7z`) | https://f4se.silverlock.org |
| 2 | **Address Library AIO** | https://www.nexusmods.com/fallout4/mods/47327 |
| 3 | **Addictol** + **Addictol Crash Logger** (two files) | https://www.nexusmods.com/fallout4/mods/84214 |
| 4 | **High FPS Physics Fix** | https://www.nexusmods.com/fallout4/mods/44798 |
| 5 | **Unofficial Fallout 4 Patch** | https://www.nexusmods.com/fallout4/mods/4598 |
| 6 | **Community Fixes Merged** | https://www.nexusmods.com/fallout4/mods/74945 |
| 7 | **TMR Glitchfinder AIO** | https://www.nexusmods.com/fallout4/mods/74949 |
| 8 | **Weapon Debris Crash Fix** | https://www.nexusmods.com/fallout4/mods/48078 |
| 9 | **Previsibines Repair Pack (Stable)** | https://www.nexusmods.com/fallout4/mods/46403 |
| 10 | Engine fixes (optional but cheap): 47760, 83252, 83433, 73849, 92024, 106989, 23389, 27445, 79853 (PRP file), 98544 | `https://www.nexusmods.com/fallout4/mods/<id>` |

**Recommended (Tier 2)**: MCM 21497, HUDFramework 20309, FallUI HUD 51813 (+ family),
XDI 27216, 27479, 83706, **Lightweight Lighting 57680**, Gloomy Glass 62518,
**Targeted Textures 62958**, **Vivid Fallout AIO 2K 25714**, 68599, 97214, 99314,
101600, 71990, 75054, 72021, LOD set 80276 → 61884 → 63191 → 63198 → 70237.

**Tier 3** can wait for a second prep night. Full list with folders: `mod-list.txt`.

### A4. Extract + deploy (15 min)

```bash
cd ~/mods/fallout4
./extract_mods.sh                       # read the NOTES block: FOMOD options it did not copy
./deploy_mods.sh --list-plugins         # every .esm/.esp/.esl it found, by folder
```

Sort with LOOT and write the result into `loadorder.txt`:

```bash
flatpak install -y flathub io.github.loot.loot
flatpak override --user io.github.loot.loot --filesystem=$HOME/.local/share/Steam:ro   # + your NVMe library path
flatpak run io.github.loot.loot     # Fallout 4 → game path + local app data path (tools_reference.md) → Sort
```

Hand-check: UFO4P → CommunityFixesMerged → ... → `PPF.esm`, `PRP.esp` last.
Then:

```bash
./deploy_mods.sh --dry-run              # what would link where; real files are never overwritten
./deploy_mods.sh                        # symlinks into Data/, F4SE into the game root, writes plugins.txt
```

### A5. INIs, HFPF config, launch line (10 min)

```bash
MYG="$(find ~/.local/share/Steam /media /mnt -maxdepth 6 -type d -path '*compatdata/377160/pfx/drive_c/users/steamuser/Documents/My Games/Fallout4' 2>/dev/null | head -1)"
cp config/Fallout4Custom.ini "$MYG/Fallout4Custom.ini"
# Merge config/Fallout4Prefs-tuning.ini into "$MYG/Fallout4Prefs.ini" section by section
# (bNVFlexEnable=0 is the one that matters most).
# Merge config/HighFPSPhysicsFix.ini into <game root>/Data/F4SE/Plugins/HighFPSPhysicsFix.ini;
# set InGameFPS / BudgetMaxFPS to your monitor's refresh rate.
```

Steam → Fallout 4 → Properties → Launch Options (from `config/steam-launch-options.txt`):

```
bash -c 'exec "${@/Fallout4Launcher.exe/f4se_loader.exe}"' -- %command%
```

### A6. Validate, lock, test drive (20 min)

```bash
./check_setup.sh                        # 0 errors required
chmod a-w "$(dirname "$MYG")/../../../../../../appmanifest_377160.acf" 2>/dev/null || \
  chmod a-w ~/.local/share/Steam/steamapps/appmanifest_377160.acf    # version lock (adjust for your library)
mkdir -p mod_files/_vanilla_1.11.240 && cp "<game root>/Fallout4.exe" mod_files/_vanilla_1.11.240/
```

Launch from Steam. Throwaway new game:

- [ ] Main menu shows the F4SE version in the console (`~` then `getf4seversion`)
- [ ] `Documents/My Games/Fallout4/F4SE/f4se.log` and `Addictol.log` exist; no `crash-*.log`
- [ ] **Sound works.** If not: `protontricks 377160 xact_64`, relaunch
- [ ] Sanctuary → Concord: no purple textures, FPS pinned at your refresh rate, drop a tin can (physics sane)
- [ ] MCM menu present in the pause menu (Tier 2)
- [ ] Diamond City market: readable interiors (Lightweight Lighting), no floating grass at the Sanctuary bridge (PRP)
- [ ] Skyline from Sanctuary hill shows the new LOD (FOLIP)

Anything red → `FO4_BUILD_SHEET.md` "Troubleshooting order", or `./deploy_mods.sh --clean` restores vanilla Data instantly.

---

## Session B — Game Night

1. `./backup/backup_fo4_saves.sh`
2. `./check_setup.sh` (catches a sneaky Steam update before it costs you the evening)
3. Launch, new character. First hour: play, don't tune.
4. Afterwards: `journalctl --user -u fo4-backup.service -n 5`

---

## Quick troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Crash on launch, "f4se" in the log or nothing | Steam updated the game; F4SE/Address Library/Addictol stale | `./check_setup.sh` names the mismatch; update all three the same day; re-lock manifest |
| Launches vanilla launcher instead of F4SE | launch line missing/typo | `config/steam-launch-options.txt` |
| No sound | XAudio under Wine with F4SE | `protontricks 377160 xact_64` or `WINEDLLOVERRIDES="xaudio2_7=n,b"`; if it broke after Addictol, toggle its AudioSwitch module |
| Instant crash when shooting | Weapon Debris on | `bNVFlexEnable=0` + Weapon Debris Crash Fix |
| Physics wild / loading at 30 fps | external fps limiter or HFPF not loaded | remove MangoHud/DXVK limiters; check HFPF ini |
| Purple/black textures | loose files disabled | `Fallout4Custom.ini` `[Archive]` lines |
| Missing master on load | plugins.txt order | `./check_setup.sh` prints the offending pair; fix `loadorder.txt`, redeploy |
| Everything broke | | `./deploy_mods.sh --clean` = vanilla Data again; saves untouched |
