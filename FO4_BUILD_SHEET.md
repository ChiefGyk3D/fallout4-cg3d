# FALLOUT 4 LINUX (STEAM + PROTON) BUILD SHEET

> **STATUS: TESTING — YMMV.** Foundation decisions below are research-backed
> (sources in `tools_reference.md`) but this build has not yet been run on the
> target machine. Validate tier by tier; keep backups (`backup/`).

## GOAL

A vanilla-plus Fallout 4 on Linux: fix the bugs, modernize the visuals and
QoL for an RTX 5070 Ti, keep the game's identity intact. Same philosophy and
repo layout as [morrowind-cg3d](https://github.com/ChiefGyk3D/morrowind-cg3d),
minus the OpenMW layer: here the engine is Bethesda's own, run through Proton.

## THE FOUNDATION DECISIONS (read first)

| Decision | Choice | Why |
|---|---|---|
| **Game version** | **Steam current: 1.11.240** (18 Aug 2026). Do NOT downgrade. | F4SE 0.7.9 and every core F4SE mod (Address Library, Addictol, High FPS Physics Fix, MCM, Place Everywhere) ship 1.11.240 builds. The Midnight Ride guide dropped downgrading in Jul 2026. 1.11.x also raised the BA2 limit 256 → 1024. |
| **Version lock** | Lock `appmanifest_377160.acf` + archive exe/BA2s | Bethesda patched 6 times since Nov 2025; each one breaks F4SE for ~2 days. A surprise update on game night is the #1 risk. |
| **Script extender** | **F4SE 0.7.9** (for 1.11.240) | Update F4SE the same day as any game patch or it crashes on launch. |
| **Crash/memory layer** | **Addictol** (one DLL: Buffout 4 + X-Cell + memory manager + crash logger) | Buffout 4 NG does not support the 1.11 "Anniversary" line; Buffout AE/MiniBuff is end-of-life and points to Addictol. No Baka ScrapHeap on top (conflicts with the memory manager). |
| **Mod manager** | **This repo's scripts**: numbered mod folders → `Data/` via symlinks, generated `plugins.txt`, LOOT (Flatpak) for sorting | Every Linux guide agrees manual works. Nexus Mods App is dead (retired Jan 2026), Limo dormant since May 2025, Vortex-on-Linux still unshipped. Optional GUI: MO2 via MO2-LINT 7.0.0 (Steam compat tool). |
| **Proton** | **Proton 11.0-2** (fallback GE-Proton11-7 for NVAPI/CUDA) | MO2-LINT: "Fallout 4 no longer works with Proton 9". |
| **GPU driver** | NVIDIA **open kernel modules, 570+** | Blackwell (50-series) has no proprietary-branch support. |
| **FPS** | Cap via **High FPS Physics Fix only** | Engine physics are frame-tied; external limiters (MangoHud, DXVK_FRAME_RATE) fight the fix. |
| **Weapon Debris** | **OFF** | NVIDIA FleX crashes on every Turing-or-newer GPU including 50-series. |

## FOLDER LAYOUT (as used by this build)

```
~/mods/fallout4/                     # this repo
├── mod_files/                       # downloaded archives (not in git)
├── mods/                            # extracted, numbered, one mod per folder
│   ├── 001_f4se/                    # goes to GAME ROOT, not Data (deploy_mods.sh handles it)
│   ├── 002_address_library/
│   ├── 003_addictol/
│   ├── 004_high_fps_physics_fix/
│   ├── 005_ufo4p/
│   ├── 006_prp/
│   ├── 1xx_.../                     # Tier 2: visuals
│   ├── 2xx_.../                     # Tier 3: UI / QoL
│   ├── 3xx_.../                     # Tier 4: audio / polish
│   └── 9xx_.../                     # patches, last
├── loadorder.txt                    # plugin order -> plugins.txt (LOOT-sorted, hand-checked)
├── config/                          # ready-to-copy INI snippets + launch options
├── backup/                          # save snapshots + systemd timer
└── saves_backup_*/                  # not in git
```

Each mod folder holds the mod's **Data-relative** layout at its root (`meshes/`,
`textures/`, `*.esp`, `*.ba2`, `F4SE/Plugins/...`). Mods that install to the
game root (F4SE itself) are flagged in `deploy_mods.sh`.

## PATHS (Steam Proton)

Steam root on Pop!_OS (.deb Steam): `~/.steam/steam` → `~/.local/share/Steam`.
If the game lives on the 4 TB NVMe library, replace `<library>` accordingly
(`steamapps/libraryfolders.vdf` lists them). App ID **377160**.

| What | Path |
|---|---|
| Game root | `<library>/steamapps/common/Fallout 4/` |
| Game Data | `<library>/steamapps/common/Fallout 4/Data/` |
| Proton prefix | `<library>/steamapps/compatdata/377160/pfx/` |
| INIs + saves | `<pfx>/drive_c/users/steamuser/Documents/My Games/Fallout4/` (`Fallout4.ini`, `Fallout4Prefs.ini`, `Fallout4Custom.ini`, `Saves/`, `F4SE/` logs) |
| plugins.txt | `<pfx>/drive_c/users/steamuser/AppData/Local/Fallout4/plugins.txt` |
| App manifest (version lock) | `<library>/steamapps/appmanifest_377160.acf` |

## PREP CHECKLIST

- [ ] Steam Fallout 4 installed (GOTY / all DLC), launched **once** with the vanilla launcher to generate INIs, then never again (it rewrites Prefs)
- [ ] Steam → Properties → Compatibility → Proton 11.0-2
- [ ] Steam → Properties → Updates → "Only update this game when I launch it", then lock the manifest (below)
- [ ] `nvidia-smi` shows 570+ and `/proc/driver/nvidia/version` reports the **Open** kernel module
- [ ] Steam Cloud for Fallout 4 **off** (modded saves + cloud quota are a bad mix; a fresh prefix can silently overwrite the cloud save)
- [ ] `backup/` timer installed; one manual snapshot taken
- [ ] Archives in `mod_files/`, extracted with `./extract_mods.sh`, deployed with `./deploy_mods.sh`
- [ ] `./check_setup.sh` reports 0 errors before every launch

## VERSION LOCK

```bash
LIB=~/.local/share/Steam            # or your NVMe library root
chmod a-w "$LIB/steamapps/appmanifest_377160.acf"
# Keep a rollback kit next to the archives:
mkdir -p ~/mods/fallout4/mod_files/_vanilla_1.11.240
cp "$LIB/steamapps/common/Fallout 4/"{Fallout4.exe,steam_api64.dll} ~/mods/fallout4/mod_files/_vanilla_1.11.240/
```

Steam will report "missing file privileges" instead of updating. To take a
future patch on purpose: `chmod u+w` the manifest, update, then wait for the
matching F4SE + Address Library + Addictol builds before playing. Full rollback
via DepotDownloader is in `tools_reference.md`. *(Unconfirmed on Linux: some
Windows reports say Steam refuses to launch while the manifest is locked. If
that happens, unlock, launch, re-lock.)*

## LAUNCH

No manager (this repo's default) — Steam → Properties → Launch Options:

```
bash -c 'exec "${@/Fallout4Launcher.exe/f4se_loader.exe}"' -- %command%
```

That swaps the vanilla launcher for F4SE's loader inside Proton. Add
`PROTON_ENABLE_NVAPI=1 ` in front only if you install the "Upscaling" DLAA
mod. Never add an external FPS limiter.

With MO2-LINT instead: Steam launches MO2 as the compatibility tool; pick the
**F4SE** executable in MO2's dropdown; no launch options needed.

## INI ESSENTIALS

`config/Fallout4Custom.ini` (loose-file loading; mandatory for every mod that
ships loose files):

```ini
[Archive]
bInvalidateOlderFiles=1
sResourceDataDirsFinal=
```

`config/Fallout4Prefs-tuning.ini` has the 5070 Ti display block (4096 shadow
maps, 20000 shadow distance, godrays Ultra, 16x AF, TAA, HBAO+, Weapon Debris
OFF, borderless). `uGridsToLoad` stays at **5** (save-breaking otherwise).
FPS cap, vsync and loading-screen speed are owned by
`config/HighFPSPhysicsFix.ini`, not by the INIs.

## TIERS (checklists; full rationale in `fo4_install_order.md`)

### Tier 1 — Foundation (mandatory, test before anything else)
- [ ] 001 F4SE 0.7.9 (game root)
- [ ] 002 Address Library for F4SE Plugins (All-In-One, 1.11.240 file)
- [ ] 003 Addictol
- [ ] 004 High FPS Physics Fix (Sept 2026 build)
- [ ] 005 Unofficial Fallout 4 Patch
- [ ] 006 Previs Repair Pack (PRP)
- [ ] 007 Mod Configuration Menu (1.11.240 build)

Validation: launches through F4SE (`F4SE/f4se.log` written), Addictol crash
log dir appears, Concord + Diamond City + Boston Common stable, no purple
textures, FPS capped at your refresh rate with physics sane (drop a tin can).

### Tier 2 — Visuals · Tier 3 — UI/QoL · Tier 4 — Audio/polish
See `fo4_install_order.md` and `mod-list.txt` (populated from the mod research).

## TROUBLESHOOTING ORDER

1. Crash on launch right after a Steam update → F4SE/Address Library/Addictol
   version mismatch. `./check_setup.sh` names the mismatch.
2. Crash in-game with a `crash-*.log` from Addictol → read the top of the log;
   the offending plugin/mesh is usually named.
3. Disable in this order: Tier 4 → Tier 3 → texture packs → lighting/weather
   → PRP patches → Tier 1 non-essentials. Never remove F4SE/Address
   Library/Addictol/UFO4P from a save that has them.
4. Weapon Debris on = instant crash on this GPU. Check it first.
