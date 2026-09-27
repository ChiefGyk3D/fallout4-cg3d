#!/bin/bash
set -euo pipefail

# Fallout 4 mod deployer (Linux / Proton) — the "mod manager" of this repo.
#
# Deploys mods/<NNN_name>/ into the game's Data/ folder as SYMLINKS, in folder
# order (later folders win on conflicts), records every link in
# deploy_manifest.txt so it can be undone cleanly, and generates plugins.txt
# from loadorder.txt. Folders containing f4se_loader.exe deploy to the GAME
# ROOT instead of Data/. A folder is skipped if it contains a file named
# .disabled.
#
# Usage:
#   ./deploy_mods.sh                 deploy (re-deploys from scratch: clean first)
#   ./deploy_mods.sh --dry-run       show what would happen
#   ./deploy_mods.sh --clean         remove everything this script deployed
#   ./deploy_mods.sh --list-plugins  list every plugin across mods/ (to fill loadorder.txt)
#   ./deploy_mods.sh --copy          copy files instead of symlinking (slower, portable)
#
# Overrides via env: MODS_DIR, GAME_ROOT, PFX (prefix), LOADORDER.
# Vanilla files are never overwritten: a real (non-symlink) file at a target
# path is reported and left alone. Loose files override BA2 content anyway.

APPID=377160
REPO="$(cd "$(dirname "$0")" && pwd)"
MODS="${MODS_DIR:-$REPO/mods}"
LOADORDER="${LOADORDER:-$REPO/loadorder.txt}"
MANIFEST="$REPO/deploy_manifest.txt"
MODE=deploy; DRY=0; COPY=0
for a in "$@"; do case "$a" in --dry-run) DRY=1;; --clean) MODE=clean;; --list-plugins) MODE=list;; --copy) COPY=1;; *) echo "unknown arg $a" >&2; exit 2;; esac; done

# --- locate game root + prefix across Steam libraries ---
STEAM_ROOTS=("$HOME/.steam/steam" "$HOME/.local/share/Steam" "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam")
libs() {
    local r vdf; for r in "${STEAM_ROOTS[@]}"; do
        [[ -d "$r/steamapps" ]] && echo "$r"
        vdf="$r/steamapps/libraryfolders.vdf"; [[ -f "$vdf" ]] && grep -oP '"path"\s+"\K[^"]+' "$vdf"
    done | awk '!s[$0]++'
}
if [[ -z "${GAME_ROOT:-}" ]]; then
    while IFS= read -r l; do [[ -d "$l/steamapps/common/Fallout 4/Data" ]] && { GAME_ROOT="$l/steamapps/common/Fallout 4"; break; }; done < <(libs)
fi
if [[ -z "${PFX:-}" ]]; then
    while IFS= read -r l; do [[ -d "$l/steamapps/compatdata/$APPID/pfx" ]] && { PFX="$l/steamapps/compatdata/$APPID/pfx"; break; }; done < <(libs)
fi
[[ -n "${GAME_ROOT:-}" && -d "$GAME_ROOT/Data" ]] || { echo "ERROR: Fallout 4 game root not found (set GAME_ROOT=)." >&2; exit 1; }
DATA="$GAME_ROOT/Data"
PLUGINS_TXT="${PFX:+$PFX/drive_c/users/steamuser/AppData/Local/Fallout4/plugins.txt}"

log() { echo "$*"; }
run() { if (( DRY )); then echo "    [dry] $*"; else "$@"; fi; }

# case-insensitive directory resolution so "Textures" and "textures" merge
ci_child() { # ci_child PARENT NAME -> existing child path with matching name (any case) or PARENT/NAME
    local parent="$1" name="$2" hit
    hit=$(find "$parent" -mindepth 1 -maxdepth 1 -iname "$name" -print -quit 2>/dev/null || true)
    [[ -n "$hit" ]] && echo "$hit" || echo "$parent/$name"
}
resolve_target() { # resolve_target BASE REL -> BASE/<rel with existing-case dirs>
    local base="$1" rel="$2" part parts
    local cur="$base"
    local dir="${rel%/*}"
    local file="${rel##*/}"
    if [[ "$dir" != "$rel" ]]; then
        IFS='/' read -ra parts <<< "$dir"
        for part in "${parts[@]}"; do cur=$(ci_child "$cur" "$part"); done
    fi
    echo "$cur/$(basename "$(ci_child "$cur" "$file")")"
}

clean() {
    [[ -f "$MANIFEST" ]] || { log "Nothing deployed (no $MANIFEST)."; return; }
    local n=0 line
    log "Removing previously deployed links..."
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if [[ -L "$line" ]]; then run rm -f "$line"; n=$((n+1))
        elif [[ -f "$line" ]] && grep -qxF "COPY" <(head -1 "$MANIFEST"); then run rm -f "$line"; n=$((n+1)); fi
    done < <(tail -n +2 "$MANIFEST")
    # prune empty dirs we may have created (inside Data only; never the game root)
    (( DRY )) || find "$DATA" -mindepth 1 -type d -empty -delete 2>/dev/null || true
    (( DRY )) || rm -f "$MANIFEST"
    log "  removed $n entries."
}

list_plugins() {
    echo "# plugins found across $MODS (folder order). Paste the ones you enable into loadorder.txt"
    local d; for d in "$MODS"/*/; do
        d=${d%/}; [[ -f "$d/.disabled" ]] && continue
        find "$d" -maxdepth 1 -type f \( -iname '*.esm' -o -iname '*.esl' -o -iname '*.esp' \) -printf "%f\t[$(basename "$d")]\n" | sort
    done
}

deploy() {
    [[ -d "$MODS" ]] || { echo "ERROR: $MODS not found. Run ./extract_mods.sh first." >&2; exit 1; }
    clean
    log "Deploying into: $DATA"
    (( DRY )) || { echo "$([[ $COPY == 1 ]] && echo COPY || echo SYMLINK)" > "$MANIFEST"; }
    local d rel src dst root_mode n_links=0 n_over=0 n_skip=0 f
    for d in "$MODS"/*/; do
        d=${d%/}
        if [[ -f "$d/.disabled" ]]; then log "  skip (disabled): $(basename "$d")"; continue; fi
        root_mode=0; [[ -e "$d/f4se_loader.exe" ]] && root_mode=1
        log "  $(basename "$d")$( (( root_mode )) && echo '  -> GAME ROOT')"
        while IFS= read -r -d '' f; do
            rel="${f#"$d"/}"
            case "$rel" in fomod/*|*.txt|*.md|readme*|README*|*.url|*.jpg|*.png|*.gif|*.pdf) [[ "$rel" == *.esp || "$rel" == *.esm ]] || continue ;; esac
            if (( root_mode )); then dst=$(resolve_target "$GAME_ROOT" "$rel"); else dst=$(resolve_target "$DATA" "$rel"); fi
            if [[ -e "$dst" && ! -L "$dst" ]]; then
                # a real file: vanilla or hand-installed. Never clobber.
                n_skip=$((n_skip+1)); (( DRY )) && echo "    [keep real file] $rel"; continue
            fi
            [[ -L "$dst" ]] && n_over=$((n_over+1))
            run mkdir -p "$(dirname "$dst")"
            if (( COPY )); then run cp -af "$f" "$dst"; else run ln -sfn "$f" "$dst"; fi
            (( DRY )) || echo "$dst" >> "$MANIFEST"
            n_links=$((n_links+1))
        done < <(find "$d" -type f -print0)
    done
    log "  deployed $n_links files ($n_over overridden by a later folder, $n_skip real files left untouched)."
    write_plugins
}

write_plugins() {
    [[ -f "$LOADORDER" ]] || { log "No $LOADORDER; plugins.txt not written."; return; }
    [[ -n "$PLUGINS_TXT" ]] || { log "Prefix not found; plugins.txt not written (set PFX=)."; return; }
    local out="" p missing=0 lower
    # index of plugin files present in Data (case-insensitive)
    local idx; idx=$(find "$DATA" -maxdepth 1 \( -iname '*.esm' -o -iname '*.esl' -o -iname '*.esp' \) -printf '%f\n' | tr '[:upper:]' '[:lower:]' | sort -u)
    while IFS= read -r p; do
        p="${p%%#*}"; p="${p%"${p##*[![:space:]]}"}"; p="${p#"${p%%[![:space:]]*}"}"
        [[ -z "$p" ]] && continue
        lower=$(printf '%s' "$p" | tr '[:upper:]' '[:lower:]')
        if ! grep -qxF "$lower" <<< "$idx"; then log "  WARNING: loadorder.txt lists '$p' but it is not in Data/"; missing=$((missing+1)); fi
        out+="*$p"$'\n'
    done < "$LOADORDER"
    log "Writing plugins.txt -> $PLUGINS_TXT ($(grep -c . <<< "$out") plugins, $missing missing)"
    if (( DRY )); then printf '%s' "$out" | sed 's/^/    /'; return; fi
    mkdir -p "$(dirname "$PLUGINS_TXT")"
    [[ -f "$PLUGINS_TXT" ]] && cp -a "$PLUGINS_TXT" "$PLUGINS_TXT.bak"
    { echo "# Generated by deploy_mods.sh from loadorder.txt on $(date -Iseconds)"; printf '%s' "$out"; } > "$PLUGINS_TXT"
}

case "$MODE" in
    clean) clean ;;
    list) list_plugins ;;
    deploy) deploy; echo ""; echo "Next: ./check_setup.sh" ;;
esac
