# Fallout 4 on Linux — Tools Reference

Tools used in this build, with setup and usage notes. Companion to
`FO4_BUILD_SHEET.md`. STATUS: TESTING — YMMV.

---

## F4SE — Fallout 4 Script Extender

**Site**: https://f4se.silverlock.org · **Source/tags**: https://github.com/ianpatt/f4se/tags
**Version pairing**: 0.7.9 ↔ game 1.11.240 · 0.7.8 ↔ 1.11.221 · 0.7.7 ↔ 1.11.191 · 0.6.23 ↔ 1.10.163

Installs to the **game root** (not Data): `f4se_loader.exe`, `f4se_1_11_240.dll`,
`f4se_steam_loader.dll`, plus `Data/F4SE/`. `deploy_mods.sh` handles the root
placement for folder `001_f4se`. F4SE ships within ~2 days of each Bethesda
patch; a game update without a matching F4SE = crash on launch, which
`check_setup.sh` detects by comparing the exe version with the DLL name.

Logs: `<pfx>/drive_c/users/steamuser/Documents/My Games/Fallout4/F4SE/f4se.log`

---

## Addictol — crash logger + engine fixes

**Repo**: https://github.com/Dear-Modding-FO4/Addictol · **Nexus**: 84214
One F4SE DLL that replaces Buffout 4 / NG / AE, X-Cell, Baka ScrapHeap, Baka
MaxPapyrusOps, Faster Workshop. 94 toggleable modules in `Data/F4SE/Plugins/Addictol.toml`.
Hard-requires Address Library. Supports OG 1.10.163, NG 1.10.984, AE 1.11.240
with a single build.

- Crash logs: `Documents/My Games/Fallout4/F4SE/crash-*.log` (Crash Logger is a
  separate download on the same page). The top of the log names the culprit.
- Module outcomes: `Addictol.log` next to `f4se.log`.
- Linux: the MiniBuff page's Proton advice (disable InteriorNavCut multithreading
  and the CreateD3DAndSwapChain patch) may apply to the equivalent Addictol
  modules if you see interior stutter or a black window. Unconfirmed.
- Do NOT stack with any of the mods it replaces.

---

## High FPS Physics Fix

**Nexus**: 44798 · **Source**: https://github.com/AntoniX35/High-FPS-Physics-Fix
Owns the frame cap, vsync and loading-screen speed. Config: `Data/F4SE/Plugins/HighFPSPhysicsFix.ini`
(our recommended values: `config/HighFPSPhysicsFix.ini`). Never combine with an
external limiter (MangoHud fps limit, `DXVK_FRAME_RATE`). The separate "High
FPS Fix" (107877) / "Physics Fixes" (107879) mods are NOT compatible with it.

---

## LOOT — load order sorter (native Flatpak)

```bash
flatpak install flathub io.github.loot.loot        # 0.29.2, Aug 2026
flatpak override --user io.github.loot.loot --filesystem=$HOME/.local/share/Steam:ro   # + your NVMe library
flatpak run io.github.loot.loot
```

Settings → Fallout 4 → game path = `<library>/steamapps/common/Fallout 4`,
local app data path = `<pfx>/drive_c/users/steamuser/AppData/Local/Fallout4`.
Sort, review, then copy the order into `loadorder.txt` (this repo generates
`plugins.txt` from it via `deploy_mods.sh`). Hand-check after sorting: UFO4P →
CFM → ... → PRP last among world edits. Linux tarballs were discontinued; Flatpak
is the only Linux build.

---

## DepotDownloader — version rollback kit

**Releases**: https://github.com/SteamRE/DepotDownloader (3.4.0 ships `DepotDownloader-linux-x64.zip`, self-contained)

```bash
./DepotDownloader -app 377160 -depot <depot> -manifest <manifest> -username <you> -remember-password -dir out
```

Depots: 377161 (content a), 377162 (exe), 377163 (content b), 377164 (English).
Known 1.10.163 manifests (from Steam guides): 377161 `7497069378349273908`,
377162 `5847529232406005096`, 377163 `5819088023757897745`, 377164
`2178106366609958945`. Current-version manifest IDs come from
steamdb.info/depot/377162/manifests. Steam's own console also works:
`steam://open/console` → `download_depot 377160 <depot> <manifest>`.
Cheaper: keep the vanilla exe/BA2 copy made in `FO4_BUILD_SHEET.md` § Version lock.

---

## Mod managers (if you want a GUI instead of this repo's scripts)

| Option | State (Sept 2026) | Verdict |
|---|---|---|
| **MO2 via MO2-LINT 7.0.0** (https://github.com/Furglitch/modorganizer2-linux-installer) | Active; installs MO2 2.5.2 as a Steam compat tool, bundles protontricks, Proton 11 | The community standard and the only manager The Midnight Ride supports. Launch: Steam → MO2 → pick "F4SE". |
| **Amethyst Mod Manager** (https://github.com/ChrisDKN/Amethyst-Mod-Manager) | v2.5.x, Sept 2026; native, MO2-style, LOOT built in, FOMOD, VFS deploy | Strongest native alternative; TMR's FAQ points here. |
| **Fluorine Manager** (https://github.com/SulfurNitride/Fluorine-Manager) | 0.3.x; MO2 port with FUSE VFS | Promising, early. |
| Limo | last release May 2025 | Dormant; skip. |
| Nexus Mods App | retired Jan 2026 | Dead; skip. |
| Vortex (Wine) | native Linux Vortex promised, not shipped | Skip. |

This repo's `deploy_mods.sh` (numbered folders → symlinks into `Data/` +
generated `plugins.txt`) is the reproducible path; every Linux guide agrees
manual install works. FOMODs: the extractor copies the core folders and lists
the optional ones; pick by reading `fomod/ModuleConfig.xml`.

---

## protontricks + the F4SE no-audio fix

```bash
pip install --user protontricks        # 1.14.1; or the Flatpak com.github.Matoking.protontricks
protontricks 377160 xact_64            # if the game has NO SOUND when launched via F4SE
```

Alternative: launch option `WINEDLLOVERRIDES="xaudio2_7=n,b" bash -c '...'`.
Addictol's AudioSwitch (XAudio2.7) module interacts with this; if audio breaks
after adding Addictol, toggle that module in `Addictol.toml`.

`protontricks-launch --appid 377160 f4se_loader.exe` runs F4SE inside the
prefix without touching Steam launch options (handy for testing).

---

## LOD generation (xLODGen / FO4LODGen)

Windows tools; run inside the prefix (`protontricks-launch --appid 377160 xLODGenx64.exe`)
or use FOLIP's / TMR's pregenerated Object LOD package. Regenerate after
changing any mod that adds exterior objects. BethINI Pie (TMR's INI tool) is
Python/Qt and runs natively.

---

## Useful diagnostic commands

```bash
# Pre-launch validation (paths, F4SE/game version match, INIs, plugins.txt, driver):
~/mods/fallout4/check_setup.sh

# Where is the prefix?
find ~/.local/share/Steam /media -maxdepth 4 -type d -name 377160 2>/dev/null

# F4SE loaded?  (last lines of the loader log)
tail -20 "<pfx>/drive_c/users/steamuser/Documents/My Games/Fallout4/F4SE/f4se.log"

# Latest crash log
ls -t "<pfx>/drive_c/users/steamuser/Documents/My Games/Fallout4/F4SE/"crash-*.log | head -1

# Active plugins
cat "<pfx>/drive_c/users/steamuser/AppData/Local/Fallout4/plugins.txt"

# Proton log for a launch failure (PROTON_LOG=1 in launch options)
tail -50 ~/steam-377160.log

# GPU driver: must be Open kernel module, 570+
cat /proc/driver/nvidia/version
```

## References

- The Midnight Ride (vanilla-plus reference guide): https://themidnightride.moddinglinked.com/ · mirror https://github.com/ModdingLinked/The-Midnight-Ride
- FUSION modlist (heavier vanilla-plus visuals): https://github.com/SpringHeelJon/FO4-FUSION
- PRP: https://www.nexusmods.com/fallout4/mods/46403 · FOLIP wiki: https://stepmodifications.org/wiki/Fallout4:Far_Object_LOD_Improvement_Project
- UFO4P history: https://www.afkmods.com/Unofficial%20Fallout%204%20Patch%20Version%20History.html
- Linux F4SE audio: https://steamcommunity.com/app/377160/discussions/0/3318610798942124148/
- Proton: https://github.com/ValveSoftware/Proton/tags · GE: https://github.com/GloriousEggroll/proton-ge-custom
- Steam Cloud hazard on fresh prefixes: https://github.com/ValveSoftware/steam-for-linux/issues/12094
