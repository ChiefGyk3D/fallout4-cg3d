#!/bin/bash
set -euo pipefail

# Fallout 4 (Steam + Proton) pre-launch health check. STATUS: TESTING.
#   - finds the game root and the Proton prefix (any Steam library)
#   - F4SE present in game root and its DLL matches the game exe version
#   - Address Library file for that version; Addictol + High FPS Physics Fix present
#   - Fallout4Custom.ini has the loose-file [Archive] lines; uGridsToLoad == 5
#   - Fallout4Prefs.ini: Weapon Debris OFF (bNVFlexEnable=0), HD DLC absent
#   - plugins.txt: every entry exists in Data/ (case-insensitive), no duplicates,
#     every master a plugin declares is present AND loads before it
#   - deployed symlinks not dangling; appmanifest lock; Proton mapping
#   - NVIDIA: driver >= 570 and the Open kernel module (Blackwell requirement)
# Usage: ./check_setup.sh    (env overrides: GAME_ROOT, PFX)

APPID=377160
ERRORS=0; WARNINGS=0
err()  { echo "  ERROR: $*";   ERRORS=$((ERRORS+1)); }
warn() { echo "  WARNING: $*"; WARNINGS=$((WARNINGS+1)); }
ok()   { echo "  ok: $*"; }

STEAM_ROOTS=("$HOME/.steam/steam" "$HOME/.local/share/Steam" "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam")
libs() { local r vdf; for r in "${STEAM_ROOTS[@]}"; do [[ -d "$r/steamapps" ]] && echo "$r"; vdf="$r/steamapps/libraryfolders.vdf"; [[ -f "$vdf" ]] && grep -oP '"path"\s+"\K[^"]+' "$vdf"; done | awk '!s[$0]++'; }
if [[ -z "${GAME_ROOT:-}" ]]; then while IFS= read -r l; do [[ -d "$l/steamapps/common/Fallout 4/Data" ]] && { GAME_ROOT="$l/steamapps/common/Fallout 4"; LIB="$l"; break; }; done < <(libs); fi
if [[ -z "${PFX:-}" ]]; then while IFS= read -r l; do [[ -d "$l/steamapps/compatdata/$APPID/pfx" ]] && { PFX="$l/steamapps/compatdata/$APPID/pfx"; break; }; done < <(libs); fi
LIB="${LIB:-$(dirname "$(dirname "$(dirname "${GAME_ROOT:-/x/y/z}")")")}"

echo "--- locations ---"
[[ -n "${GAME_ROOT:-}" && -d "$GAME_ROOT/Data" ]] && ok "game root: $GAME_ROOT" || { err "Fallout 4 game root not found (GAME_ROOT=)"; }
[[ -n "${PFX:-}" && -d "$PFX" ]] && ok "prefix: $PFX" || err "Proton prefix compatdata/$APPID not found (has the game been launched once?)"
DATA="${GAME_ROOT:-/nonexistent}/Data"
MYGAMES="${PFX:-/nonexistent}/drive_c/users/steamuser/Documents/My Games/Fallout4"
PLUGINS="${PFX:-/nonexistent}/drive_c/users/steamuser/AppData/Local/Fallout4/plugins.txt"
echo ""

echo "--- game version vs F4SE ---"
GAME_VER=""
if [[ -f "$GAME_ROOT/Fallout4.exe" ]]; then
    GAME_VER=$(python3 - "$GAME_ROOT/Fallout4.exe" <<'EOF' 2>/dev/null || true
import sys,re
b=open(sys.argv[1],'rb').read()
key='ProductVersion'.encode('utf-16-le')
i=b.find(key)
if i>=0:
    s=b[i+len(key):i+len(key)+120]
    s=s.lstrip(b'\x00')
    m=re.match(rb'((?:[0-9]\x00)+(?:\.\x00(?:[0-9]\x00)+){1,3})', s)
    if m: print(m.group(1).decode('utf-16-le'))
EOF
)
    [[ -n "$GAME_VER" ]] && ok "Fallout4.exe product version: $GAME_VER" || warn "could not read Fallout4.exe version string"
else
    err "Fallout4.exe not found in game root"
fi
if [[ -f "$GAME_ROOT/f4se_loader.exe" ]]; then
    F4SE_DLL=$(find "$GAME_ROOT" -maxdepth 1 -iname 'f4se_1_*.dll' -printf '%f\n' | sort | tail -1)
    if [[ -n "$F4SE_DLL" ]]; then
        DLL_VER=$(sed -E 's/^f4se_([0-9]+)_([0-9]+)_([0-9]+)\.dll$/\1.\2.\3/I' <<< "$F4SE_DLL")
        if [[ -n "$GAME_VER" && "$GAME_VER" != "$DLL_VER"* ]]; then
            err "F4SE DLL is for $DLL_VER but the game is $GAME_VER — Steam updated the game (or F4SE is stale). Update F4SE/Address Library/Addictol together."
        else ok "F4SE runtime DLL: $F4SE_DLL"; fi
    else err "f4se_loader.exe present but no f4se_1_*.dll beside it"; fi
else
    err "F4SE not installed in game root (deploy folder 001_f4se)"
fi
if [[ -n "$GAME_VER" ]]; then
    V="${GAME_VER%.*}"; AL=$(find "$DATA/F4SE/Plugins" -maxdepth 1 -iname "version-${V//./-}-*.bin" -print -quit 2>/dev/null || true)
    [[ -n "$AL" ]] && ok "Address Library: $(basename "$AL")" || err "Address Library file version-${V//./-}-*.bin missing in Data/F4SE/Plugins (needed by every DLL mod)"
fi
for dll in Addictol.dll HighFPSPhysicsFix.dll; do
    [[ -e "$DATA/F4SE/Plugins/$dll" || -n "$(find "$DATA/F4SE/Plugins" -maxdepth 1 -iname "$dll" -print -quit 2>/dev/null)" ]] && ok "$dll present" || warn "$dll not found in Data/F4SE/Plugins"
done
for bad in Buffout4.dll Buffout4NG.dll BakaScrapHeap.dll x-cell*.dll; do
    [[ -n "$(find "$DATA/F4SE/Plugins" -maxdepth 1 -iname "$bad" -print -quit 2>/dev/null)" ]] && err "$bad present alongside Addictol — mutually exclusive, remove it"
done
echo ""

echo "--- INIs ---"
if [[ -f "$MYGAMES/Fallout4Custom.ini" ]]; then
    grep -qiE '^\s*bInvalidateOlderFiles\s*=\s*1' "$MYGAMES/Fallout4Custom.ini" && grep -qiE '^\s*sResourceDataDirsFinal\s*=\s*$' "$MYGAMES/Fallout4Custom.ini" \
        && ok "Fallout4Custom.ini: loose files enabled" || err "Fallout4Custom.ini lacks [Archive] bInvalidateOlderFiles=1 / sResourceDataDirsFinal= (see config/Fallout4Custom.ini) — loose-file mods will not load"
else err "Fallout4Custom.ini missing at $MYGAMES (copy config/Fallout4Custom.ini)"; fi
for ini in Fallout4.ini Fallout4Custom.ini; do
    [[ -f "$MYGAMES/$ini" ]] && grep -qiE '^\s*uGridsToLoad\s*=\s*([6-9]|[1-9][0-9])' "$MYGAMES/$ini" && err "$ini raises uGridsToLoad above 5 — save-breaking, revert"
done
if [[ -f "$MYGAMES/Fallout4Prefs.ini" ]]; then
    if grep -qiE '^\s*bNVFlexEnable\s*=\s*1' "$MYGAMES/Fallout4Prefs.ini"; then err "Weapon Debris (bNVFlexEnable=1) is ON — crashes on RTX 20-series and newer, set 0"; else ok "Weapon Debris off"; fi
    grep -qiE '^\s*iPresentInterval\s*=\s*0' "$MYGAMES/Fallout4Prefs.ini" && warn "iPresentInterval=0 in Prefs — leave 1 and let High FPS Physics Fix own vsync/cap"
else warn "Fallout4Prefs.ini missing — run the vanilla launcher once to generate it"; fi
HF=$(find "$DATA/F4SE/Plugins" -maxdepth 1 -iname 'HighFPSPhysicsFix.ini' -print -quit 2>/dev/null || true)
[[ -n "$HF" ]] && { grep -qiE '^\s*InGameFPS\s*=' "$HF" && ok "HighFPSPhysicsFix.ini has InGameFPS" || warn "HighFPSPhysicsFix.ini has no InGameFPS (see config/HighFPSPhysicsFix.ini)"; }
[[ -e "$DATA/DLCUltraHighResolution.esm" ]] && warn "Official HD Texture Pack DLC is installed — 58 GB, no gain, perf hit; uncheck it in Steam → DLC"
echo ""

echo "--- plugins.txt ---"
if [[ -f "$PLUGINS" ]]; then
    mapfile -t PL < <(grep -v '^#' "$PLUGINS" | sed 's/^\*//' | sed 's/\r$//' | grep -v '^\s*$')
    IDX=$(find "$DATA" -maxdepth 1 \( -iname '*.esm' -o -iname '*.esl' -o -iname '*.esp' \) -printf '%f\n' | tr '[:upper:]' '[:lower:]' | sort -u)
    declare -A SEEN=(); pos=0; found=0
    for p in "${PL[@]}"; do
        lower=$(printf '%s' "$p" | tr '[:upper:]' '[:lower:]'); pos=$((pos+1))
        [[ -n "${SEEN[$lower]:-}" ]] && { err "duplicate plugin: $p"; continue; }
        SEEN[$lower]=$pos
        if grep -qxF "$lower" <<< "$IDX"; then found=$((found+1)); else err "plugin listed but not in Data/: $p"; fi
    done
    ok "$found of ${#PL[@]} plugins present"
    # master check: parse TES4 header MAST subrecords
    if python3 - "$DATA" "${PL[@]}" <<'EOF'
import sys,os,struct
data=sys.argv[1]; order=[p.lower() for p in sys.argv[2:]]
files={f.lower():f for f in os.listdir(data) if f.lower().endswith(('.esm','.esp','.esl'))}
implicit={'fallout4.esm'}
problems=0
for i,p in enumerate(order):
    if p not in files: continue
    try:
        with open(os.path.join(data,files[p]),'rb') as fh:
            hdr=fh.read(24)
            if hdr[:4]!=b'TES4': continue
            size=struct.unpack('<I',hdr[4:8])[0]
            body=fh.read(size); j=0; masters=[]
            while j+6<=len(body):
                tag=body[j:j+4]; ln=struct.unpack('<H',body[j+4:j+6])[0]; val=body[j+6:j+6+ln]; j+=6+ln
                if tag==b'MAST': masters.append(val.rstrip(b'\x00').decode('cp1252','replace').lower())
    except Exception: continue
    for m in masters:
        if m in implicit: continue
        if m not in order: print(f"  ERROR: {files[p]} needs master {m} which is not in plugins.txt"); problems+=1
        elif order.index(m)>i: print(f"  ERROR: {files[p]} loads before its master {m}"); problems+=1
sys.exit(1 if problems else 0)
EOF
    then ok "all masters present and ordered"; else ERRORS=$((ERRORS+1)); fi
else
    err "plugins.txt not found at $PLUGINS (run ./deploy_mods.sh)"
fi
echo ""

echo "--- deployment ---"
MAN="$(dirname "$0")/deploy_manifest.txt"
if [[ -f "$MAN" ]]; then
    dang=$(tail -n +2 "$MAN" | { while IFS= read -r l; do if [[ -L "$l" && ! -e "$l" ]]; then echo "$l"; fi; done; true; } | wc -l)
    (( dang )) && err "$dang dangling symlinks in Data (mod folder moved/deleted?) — run ./deploy_mods.sh" || ok "$(($(wc -l < "$MAN")-1)) deployed files, no dangling links"
else warn "no deploy_manifest.txt — nothing deployed by deploy_mods.sh yet"; fi
echo ""

echo "--- Steam / Proton / driver ---"
ACF="$LIB/steamapps/appmanifest_$APPID.acf"
if [[ -f "$ACF" ]]; then [[ -w "$ACF" ]] && warn "appmanifest_$APPID.acf is writable — Steam can auto-update and break F4SE (FO4_BUILD_SHEET.md § Version lock)" || ok "appmanifest locked (read-only)"; fi
for cfg in "$HOME/.steam/steam/config/config.vdf" "$HOME/.local/share/Steam/config/config.vdf"; do
    [[ -f "$cfg" ]] || continue
    tool=$(awk -v id="\"$APPID\"" '$1==id{f=1} f&&/"name"/{gsub(/"/,"",$2);print $2;exit}' "$cfg" || true)
    if [[ -n "$tool" ]]; then case "$tool" in proton_9*|proton_8*|proton_7*|*Proton9*|*Proton8*) warn "Proton for FO4 is '$tool' — Proton 9 and older no longer run FO4 reliably; use Proton 11 / GE-Proton11";; *) ok "Proton tool: $tool";; esac; fi
    break
done
if command -v nvidia-smi >/dev/null 2>&1; then
    drv=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1 | tr -d ' ')
    [[ -n "$drv" ]] && { (( ${drv%%.*} >= 570 )) && ok "NVIDIA driver $drv" || err "NVIDIA driver $drv < 570 — RTX 50-series needs 570+"; }
    if [[ -r /proc/driver/nvidia/version ]]; then grep -qi 'open' /proc/driver/nvidia/version && ok "Open kernel module" || warn "proprietary kernel module detected — Blackwell requires the Open kernel modules"; fi
fi
echo ""
echo "=============================="
echo "RESULT: $ERRORS error(s), $WARNINGS warning(s)"
if (( ERRORS )); then echo "Fix errors before launching."; exit 1; fi
echo "Config looks launchable."
