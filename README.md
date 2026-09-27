<div align="center">

# chiefgyk3d's Modded Fallout 4 Build (Linux)

*The Commonwealth, remastered on Proton for an RTX 5070 Ti: fixed, sharpened, faithful.*

</div>

> [!WARNING]
> **Project status: TESTING — your mileage may vary.**
> This is the research-complete, not-yet-played-through sibling of
> [morrowind-cg3d](https://github.com/ChiefGyk3D/morrowind-cg3d). The foundation
> decisions (game version, F4SE, crash layer, Proton, deploy method) are sourced
> and current as of late September 2026, the scripts are tested against synthetic
> data, and nothing has run on the real machine yet. Follow the tier-by-tier
> validation, keep backups, and expect the first prep night to find rough edges.

Reproducible setup for a **vanilla-plus Fallout 4** on Linux (Steam + Proton). Same philosophy as the Morrowind build: fix the bugs, modernize the visuals and QoL for the hardware, add faithful content later, never change what the game *is*. There is no OpenMW here, so the foundation is Bethesda's engine on **Steam 1.11.240 + F4SE 0.7.9**, deployed by this repo's own scripts.

## Start here

| File | Purpose |
|------|---------|
| **`GAME_NIGHT_RUNBOOK.md`** | **Prep-night / game-night checklist**: every command and download in order |
| `FO4_BUILD_SHEET.md` | The foundation decisions and why, paths inside the Proton prefix, version lock, launch line |
| `fo4_install_order.md` | Tiered, layered install order with rationale; the "deliberately skipped" list |
| `mod-list.txt` | Every mod with Nexus ID, target folder, download status |
| `tools_reference.md` | F4SE, Addictol, LOOT (Flatpak), DepotDownloader rollback, managers, audio fix, diagnostics |
| `loadorder.txt` | Plugin order → `plugins.txt` (LOOT-sorted, hand-checked) |
| `extract_mods.sh` | Unpacks archives by Nexus ID into numbered mod folders; detects FOMOD / `Data/` / flat layouts |
| `deploy_mods.sh` | The "mod manager": symlinks numbered folders into `Data/` in order, F4SE to the game root, writes `plugins.txt`, cleans up after itself |
| `check_setup.sh` | Pre-launch health check: F4SE ↔ game version match, Address Library, INIs, Weapon Debris, plugins + master order, dangling links, Proton, NVIDIA driver |
| `config/` | Ready-to-copy `Fallout4Custom.ini`, `Fallout4Prefs` tuning, `HighFPSPhysicsFix.ini`, Steam launch options |
| `backup/` | Save snapshots (hardlink-deduplicated) + systemd timer; finds the prefix on any Steam library |

## The build in one paragraph

Stay on the current Steam version and lock it. F4SE + Address Library + **Addictol** (the 2026 replacement for Buffout 4/X-Cell/ScrapHeap) + **High FPS Physics Fix** as the only frame limiter. **UFO4P → Community Fixes Merged → PRP** as the patch spine. Then **Lightweight Lighting**, **Targeted Textures + Vivid Fallout**, **FOLIP** LOD, **FallUI + XDI** for the interface, and a short list of faithful gameplay tweaks (BCR, Classic Holstered Weapons, companion fixes, cut-content restorations) plus RAO audio. Weapon Debris off (it crashes every RTX card). Official HD Texture Pack DLC not installed. Everything that rebalances, replaces systems, or changes the look is on the skipped list, with reasons.

## System

- **Hardware**: RTX 5070 Ti · Ryzen 9 5950X · 64 GB RAM · 4 TB NVMe
- **OS**: Pop!_OS (Ubuntu 22.04 base), NVIDIA open kernel modules 570+
- **Game**: Steam Fallout 4 GOTY, 1.11.240, Proton 11.0-2
- **Repo lives at**: `~/mods/fallout4/` (mods and archives are gitignored)

## Quick start (rebuilding from scratch)

For the real session follow **`GAME_NIGHT_RUNBOOK.md`**; the short version:

1. Launch vanilla Fallout 4 once through Steam (generates INIs), set Proton 11, disable Steam Cloud for it, uncheck the HD Texture Pack DLC
2. `backup/`: install the timer, take a snapshot
3. Download everything in `mod-list.txt` into `mod_files/` (keep Nexus filenames)
4. `./extract_mods.sh` → `./deploy_mods.sh --list-plugins` → fill `loadorder.txt` (LOOT) → `./deploy_mods.sh`
5. Copy `config/Fallout4Custom.ini`, merge `config/Fallout4Prefs-tuning.ini` and `config/HighFPSPhysicsFix.ini`, set the launch line from `config/steam-launch-options.txt`
6. `./check_setup.sh` until 0 errors, lock the app manifest
7. Tier 1 test drive, then Tier 2, then Tier 3

## Known issues / open questions (testing status)

| Item | Status |
|------|--------|
| Nothing has run on the real machine yet | Scripts tested with synthetic archives, game root, and prefix only |
| The Midnight Ride's stance on 1.11.240 | Their changelog stops at 1.11.221 (Jul 2026); every mod in their stack has a 1.11.240 build, so we go 1.11.240 |
| Sprint Stuttering Fix / Armor Penetration Fix vs Addictol modules | Possible overlap; check `Addictol.log` |
| "Upscaling" (DLAA) mod under Proton | Unconfirmed; last thing to try |
| No sound when launched via F4SE (Linux) | Known; `protontricks 377160 xact_64` (see `tools_reference.md`) |
| Better Console / PCL-dependent mods | Not confirmed for 1.11.240; left out |

## Roadmap

- **Now**: first prep night per the runbook; fix whatever the real archives' layouts break in `extract_mods.sh`
- **Then**: Tier 2/3 validation, LOD generation (xLODGen in the prefix or pregenerated), tuned INIs
- **Later**: a "more Commonwealth" stage cherry-picked from A StoryWealth's quest mods and TMR Extended, once Tiers 1–3 are stable
- **Maybe**: MO2 via MO2-LINT or Amethyst as a GUI on top, if scripted deploy ever gets in the way

## Links

- [Fallout 4 on Steam](https://store.steampowered.com/app/377160/) · [F4SE](https://f4se.silverlock.org)
- [The Midnight Ride](https://themidnightride.moddinglinked.com/) — the vanilla-plus reference guide this build is calibrated against
- [Addictol](https://github.com/Dear-Modding-FO4/Addictol) · [PRP](https://www.nexusmods.com/fallout4/mods/46403) · [FOLIP](https://www.nexusmods.com/fallout4/mods/61884)
- [MO2-LINT](https://github.com/Furglitch/modorganizer2-linux-installer) · [Amethyst](https://github.com/ChrisDKN/Amethyst-Mod-Manager) — if you want a GUI manager
