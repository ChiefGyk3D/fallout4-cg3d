#!/bin/bash
set -euo pipefail

# Fallout 4 Mod Extraction Script (Linux)
# Unpacks every archive in mod_files/ into numbered mod folders under mods/,
# each holding the mod's DATA-RELATIVE layout at its root (meshes/, textures/,
# *.esp, *.ba2, F4SE/Plugins/...). F4SE is the exception: its folder holds the
# GAME-ROOT layout (f4se_loader.exe + Data/) and deploy_mods.sh places it there.
#
# Archive matching is by Nexus mod ID in the filename ("<Name>-<id>-<ver>-<ts>.7z"),
# so re-downloads and multi-file mods (main + optional files) just work: EVERY
# archive matching an ID is extracted into that mod's folder, in name order.
#
# Layout detection (extract_auto):
#   1. "Data/" wrapper                       -> copy its contents
#   2. FOMOD (fomod/ + option folders)       -> copy core-looking folders ("00 *",
#      "0 *", Core*, Main*, Required*, Base*) + requested extras; list the rest
#   3. single wrapper folder                 -> descend and re-check
#   4. game data at root                     -> copy flat
#
# Missing REQUIRED archives are ISSUES; missing OPTIONAL ones are NOTES.

ARCHIVES="${ARCHIVES_DIR:-$HOME/mods/fallout4/mod_files}"
MODS="${MODS_DIR:-$HOME/mods/fallout4/mods}"

ISSUES=(); NOTES=()

require_tool() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: '$1' not found. Install it ($2)." >&2; exit 1; }; }
require_tool 7z "sudo apt install p7zip-full"
command -v unrar >/dev/null 2>&1 || echo "NOTE: unrar not found; .rar archives will be skipped (sudo apt install unrar)."

[[ -d "$ARCHIVES" ]] || { echo "ERROR: archive dir not found: $ARCHIVES (download per mod-list.txt first)" >&2; exit 1; }

extract_any() {
    local archive="$1" dest="$2"; mkdir -p "$dest"
    case "${archive,,}" in
        *.rar) command -v unrar >/dev/null 2>&1 && unrar x -o+ "$archive" "$dest/" > /dev/null 2>&1 || true ;;
        *)     7z x "$archive" -o"$dest" -r -y > /dev/null 2>&1 || true ;;
    esac
}

is_data_root() {
    find "$1" -maxdepth 1 \( -iname meshes -o -iname textures -o -iname materials -o -iname sound \
        -o -iname scripts -o -iname interface -o -iname strings -o -iname f4se -o -iname mcm \
        -o -iname music -o -iname video -o -iname lodsettings -o -iname vis -o -iname 'shadersfx' \
        -o -iname '*.esp' -o -iname '*.esm' -o -iname '*.esl' -o -iname '*.ba2' -o -iname '*.ini' \) \
        -print -quit 2>/dev/null | grep -q .
}

verify() {
    [[ -n "$(find "$1" -mindepth 1 -print -quit 2>/dev/null)" ]] || { echo "  WARNING: $1 is empty."; ISSUES+=("$2: nothing extracted into $1"); }
}

# extract_auto ARCHIVE TARGET [extra FOMOD folder globs...]
extract_auto() {
    local archive="$1" target="$2"; shift 2
    local extra=("$@") tmpdir root
    tmpdir=$(mktemp -d); mkdir -p "$target"
    extract_any "$archive" "$tmpdir"; root="$tmpdir"
    while :; do
        local entries; mapfile -t entries < <(find "$root" -mindepth 1 -maxdepth 1 -not -name '__MACOSX')
        if (( ${#entries[@]} == 1 )) && [[ -d "${entries[0]}" ]] && ! is_data_root "$root" && [[ "$(basename "${entries[0]}")" != "Data" ]]; then
            root="${entries[0]}"; else break; fi
    done
    if [[ -d "$root/Data" ]] && ! [[ -e "$root/f4se_loader.exe" ]]; then
        echo "  Layout: 'Data/' wrapper"; cp -a "$root/Data"/. "$target"/
    elif [[ -d "$root/fomod" ]] || compgen -G "$root/00 *" > /dev/null; then
        echo "  Layout: FOMOD"
        local d name want copied=0 optional=()
        for d in "$root"/*/; do
            d=${d%/}; name=$(basename "$d"); [[ "$name" == fomod ]] && continue
            want=0
            case "$name" in 00\ *|0\ *|[Cc]ore*|[Mm]ain*|[Rr]equired*|[Bb]ase*|[Dd]ata) want=1 ;; esac
            local g; for g in "${extra[@]}"; do [[ "$name" == $g ]] && want=1; done
            if (( want )); then
                echo "    + $name"
                if [[ -d "$d/Data" ]]; then cp -a "$d/Data"/. "$target"/; else cp -a "$d"/. "$target"/; fi
                copied=$((copied+1))
            else optional+=("$name"); fi
        done
        # loose files at the FOMOD root (some authors put the ESP there)
        find "$root" -maxdepth 1 -type f \( -iname '*.esp' -o -iname '*.esm' -o -iname '*.esl' -o -iname '*.ba2' \) -exec cp -a {} "$target"/ \;
        if (( ${#optional[@]} )); then
            echo "    optional folders NOT copied (read fomod/ModuleConfig.xml, copy by hand if wanted):"
            printf '      - %s\n' "${optional[@]}"
            NOTES+=("$(basename "$target"): FOMOD options not copied: $(IFS=';'; echo "${optional[*]}")")
        fi
        (( copied == 0 )) && ISSUES+=("$(basename "$target"): FOMOD with no core-looking folder; pick options manually")
    elif is_data_root "$root"; then
        echo "  Layout: flat (data at root)"; cp -a "$root"/. "$target"/
    else
        echo "  WARNING: unrecognised layout; copied as-is for manual sorting."; cp -a "$root"/. "$target"/
        ISSUES+=("$(basename "$target"): unrecognised archive layout")
    fi
    rm -rf "$tmpdir"
}

# extract_id NEXUS_ID LABEL TARGET REQUIRED(1/0) [extra FOMOD globs...]
extract_id() {
    local id="$1" label="$2" target="$3" required="$4"; shift 4
    local -a found
    mapfile -t found < <(find "$ARCHIVES" -maxdepth 1 -type f -size +0 \( -iname "*-$id-*" \) -not -iname '*.part' -not -iname '*.crdownload' | sort)
    echo "[$label] (Nexus $id) -> $(basename "$target")"
    if (( ${#found[@]} == 0 )); then
        if (( required )); then echo "  MISSING ARCHIVE (pattern *-$id-*)"; ISSUES+=("$label: no archive matching *-$id-*");
        else echo "  (not downloaded — skipping)"; NOTES+=("$label: not downloaded (Nexus $id)"); fi
        return 0
    fi
    local a; for a in "${found[@]}"; do echo "  Archive: $(basename "$a")"; extract_auto "$a" "$target" "$@"; done
    verify "$target" "$label"
}

echo "=========================================="
echo "FALLOUT 4 MOD EXTRACTION"
echo "  archives: $ARCHIVES"
echo "  mods:     $MODS"
echo "=========================================="

# --- 001 F4SE (silverlock: f4se_0_07_09.7z -> folder f4se_0_07_09/ = GAME ROOT layout) ---
echo "[F4SE] -> 001_f4se (game-root layout)"
F4SE_ARCH=$(find "$ARCHIVES" -maxdepth 1 -type f -iname 'f4se_0_*.7z' -printf '%T@ %p\n' | sort -rn | head -1 | cut -d' ' -f2-)
if [[ -n "$F4SE_ARCH" ]]; then
    echo "  Archive: $(basename "$F4SE_ARCH")"
    tmp=$(mktemp -d); extract_any "$F4SE_ARCH" "$tmp"
    root=$(find "$tmp" -name f4se_loader.exe -printf '%h\n' | head -1)
    if [[ -n "$root" ]]; then mkdir -p "$MODS/001_f4se"; cp -a "$root"/. "$MODS/001_f4se"/; verify "$MODS/001_f4se" "F4SE";
    else ISSUES+=("F4SE: f4se_loader.exe not found inside $(basename "$F4SE_ARCH")"); fi
    rm -rf "$tmp"
else
    echo "  MISSING: f4se_0_07_09.7z (https://f4se.silverlock.org)"; ISSUES+=("F4SE: archive f4se_0_*.7z not found")
fi

# id | label | folder | required | extra FOMOD globs (space-separated, optional)
TIER1=(
"47327|Address Library AIO|002_address_library|1"
"84214|Addictol + Crash Logger|003_addictol|1"
"44798|High FPS Physics Fix|004_high_fps_physics_fix|1"
"104159|Hydra|005_hydra|0"
"74160|Garden of Eden PSE|006_goe_pse|0"
"60074|Random Encounter Framework|007_ref|0"
"4598|Unofficial Fallout 4 Patch|010_ufo4p|1"
"74945|Community Fixes Merged|011_community_fixes_merged|1"
"74949|TMR Glitchfinder AIO|012_glitchfinder_aio|1"
"47760|Sprint Stuttering Fix|013_sprint_stuttering_fix|0"
"83252|Empty Vendor List Fix|014_empty_vendor_list_fix|0"
"83433|Magic Effect and Spell Engine Fixes|015_magic_effect_fixes|0"
"73849|Armor Penetration Bug Fix AE|016_armor_penetration_fix|0"
"92024|Follower AI Approach Reaction Fix|017_follower_approach_fix|0"
"106989|Rain Bug Fix AE|018_rain_bug_fix|0"
"23389|Wetness Shader Fix|020_wetness_shader_fix|0"
"27445|Fixed Gobo Effects|021_fixed_gobo_effects|0"
"79853|Flutter Flicker Fixer (PRP file)|022_flutter_flicker_fixer|0|*PRP*"
"98544|Motion Vector Fixes|023_motion_vector_fixes|0"
"48078|Weapon Debris Crash Fix|024_weapon_debris_crash_fix|1"
"46403|Previsibines Repair Pack|030_prp|1"
"27019|RAW INPUT|040_raw_input|0"
)
TIER2=(
"21497|Mod Configuration Menu|100_mcm|0"
"20309|HUDFramework|101_hudframework|0"
"51813|FallUI - HUD|102_fallui_hud|0"
"27216|XDI Extended Dialogue Interface|103_xdi|0"
"27479|Crafting Highlight Fix|104_crafting_highlight_fix|0"
"83706|Workshop Highlight Fix|105_workshop_highlight_fix|0"
"57680|Lightweight Lighting|110_lightweight_lighting|0"
"62518|Gloomy Glass|111_gloomy_glass|0"
"62958|Targeted Textures|120_targeted_textures|0"
"25714|Vivid Fallout AIO|121_main_textures|0"
"65720|Luxor HD Overhaul 2K (alternative main pack)|121_main_textures|0"
"10467|Fallout 4 HD Reworked Project|122_hd_reworked|0"
"68599|Particle Patch|123_particle_patch|0"
"97214|Enhanced Vanilla Water|124_enhanced_vanilla_water|0"
"99314|Terrain Freckles Be Gone|125_terrain_freckles_be_gone|0"
"101600|Sniper Scope Overlay Overhaul|126_sniper_scope_overlay|0"
"71990|Diamond City Billboards|127_diamond_city_billboards|0"
"75054|Diamond City Supplements|128_diamond_city_supplements|0"
"72021|Goodneighbor View|129_goodneighbor_view|0"
"80276|FO4LODGen Resources|130_fo4lodgen_resources|0"
"61884|FOLIP|131_folip|0"
"63191|Far Harbor 3D Tree LODs|132_far_harbor_tree_lods|0"
"63198|Optimized Vanilla Tree LODs|133_optimized_tree_lods|0"
"70237|Northern Foothills Rocks Fix|134_northern_foothills_rocks|0"
"212|Enhanced Blood Textures|140_enhanced_blood|0"
"10840|Pip-Boy Flashlight|141_pipboy_flashlight|0"
"99130|Upscaling (DLAA)|142_upscaling|0"
"98935|This Made My Spline Stiff|143_spline_stiff|0"
)
TIER3=(
"84440|Assorted Modular Tweaks|200_assorted_modular_tweaks|0"
"41178|Bullet Counted Reload System|201_bcr|0"
"46101|Classic Holstered Weapons|202_classic_holstered_weapons|0"
"64426|Remove Ammo from Dropped Guns|203_remove_ammo_dropped_guns|0"
"96130|Remember Lockpick Angle|204_remember_lockpick_angle|0"
"11838|Less Annoying Berry Mentats|205_berry_mentats|0"
"73259|To Your Face|206_to_your_face|0"
"57838|Deadeye Weapon Effect Fix|207_deadeye_fix|0"
"75292|Simple Offence Suppression|208_simple_offence_suppression|0"
"70013|Faster Workbench Exit|209_faster_workbench_exit|0"
"107231|Dogmeat Lags Behind|210_dogmeat_lags_behind|0"
"92314|Simple Everyone's Best Friend|211_everyones_best_friend|0"
"92016|Integrated Addons|212_integrated_addons|0"
"56089|Keep Radiants in the Commonwealth|213_keep_radiants|0"
"99587|Encounter Zone Recalculation AE|214_encounter_zone_recalc|0"
"59019|Who's The General|215_whos_the_general|0"
"99080|Who's The General patch hub|215_whos_the_general|0"
"63929|Legendary Mutation Messages Fix|216_legendary_mutation_fix|0"
"64009|Unused Map Markers|217_unused_map_markers|0"
"106236|Nuka World Cut Content Restored|218_nuka_world_cut_content|0"
"29058|DLC Cut Content Restoration Project|219_dlc_cut_content|0"
"102596|Refreshing Checkpoints|220_refreshing_checkpoints|0"
"15364|Molotov Cocktail Nerf|221_molotov_nerf|0"
"9424|Place Everywhere|222_place_everywhere|0"
"26163|Unlimited Survival Mode|223_unlimited_survival|0"
"102931|Safe Travels|224_safe_travels|0"
"10189|Reverb and Ambiance Overhaul|300_rao|0"
"1544|P.A.M.S|301_pams|0"
"101798|High-Fidelity Sounds Project|302_high_fidelity_sounds|0"
"25343|Ambient Wasteland|303_ambient_wasteland|0"
)

run_tier() {
    local name="$1"; shift
    echo ""; echo "------------------------------------------"; echo "$name"; echo "------------------------------------------"
    local spec id label folder req extras
    for spec in "$@"; do
        IFS='|' read -r id label folder req extras <<< "$spec"
        # shellcheck disable=SC2086
        extract_id "$id" "$label" "$MODS/$folder" "$req" ${extras:-}
    done
}
run_tier "TIER 1 — foundation & fixes" "${TIER1[@]}"
run_tier "TIER 2 — visuals + UI (optional)" "${TIER2[@]}"
run_tier "TIER 3 — gameplay / QoL / audio (optional)" "${TIER3[@]}"

# Post-steps
if [[ -d "$MODS/003_addictol" ]] && ! find "$MODS/003_addictol" -iname 'Addictol.dll' -print -quit | grep -q .; then
    ISSUES+=("003_addictol: Addictol.dll not found at F4SE/Plugins/ — check the archive layout")
fi

echo ""; echo "=========================================="; echo "EXTRACTION COMPLETE"; echo "=========================================="
if ((${#NOTES[@]})); then echo ""; echo "NOTES (${#NOTES[@]}):"; printf '  - %s\n' "${NOTES[@]}"; fi
if ((${#ISSUES[@]})); then echo ""; echo "ISSUES (${#ISSUES[@]}):"; printf '  - %s\n' "${ISSUES[@]}"; echo ""; echo "Fix the above and re-run."; exit 1; fi
echo ""; echo "No issues. Next: ./deploy_mods.sh --list-plugins  (fill loadorder.txt)  then  ./deploy_mods.sh  then  ./check_setup.sh"
