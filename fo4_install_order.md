# Fallout 4 Mod Install Order & Layering Guide

> **STATUS: TESTING — YMMV.** Sourced from The Midnight Ride (TMR, Jul 2026 on
> 1.11.221), FUSION's public modlist, and the Addictol/PRP/FOLIP project pages.
> Nexus pages could not be read directly from the research sandbox, so exact
> current version numbers should be spot-checked at download time.

**System**: Steam Fallout 4 **1.11.240** + F4SE 0.7.9 · Proton 11 · RTX 5070 Ti · Ryzen 9 5950X · 64 GB · Pop!_OS
**Principle**: later folders win on file conflicts (deploy order = folder number). Plugin order is separate (`loadorder.txt`, LOOT-sorted then hand-checked). PRP loads **last** among world-edit plugins.

---

## Layering order (folder numbers)

1. **000s — Engine layer**: F4SE (game root), Address Library, Addictol, High FPS Physics Fix, libraries (Hydra, GoE PSE, REF)
2. **010s — Patches**: UFO4P, Community Fixes Merged, Glitchfinder AIO, engine bug fixes
3. **020s — Shader/asset fixes**: Wetness, Gobo, Flutter Flicker, Motion Vectors, Weapon Debris Crash Fix
4. **030s — PRP**: Previsibines Repair Pack (its plugin loads last; its files can deploy here)
5. **100s — UI**: MCM, HUDFramework, FallUI set, XDI, highlight fixes
6. **110s — Lighting/weather**: Lightweight Lighting, Gloomy Glass
7. **120s — Textures**: Targeted Textures, then ONE main pack (Vivid AIO or Luxor 2K), fillers, water, particles
8. **130s — LOD**: FO4LODGen Resources → FOLIP → tree/rock LOD companions → generated/pregenerated LOD
9. **140s — Optional visuals**: Upscaling (DLAA), Pip-Boy Flashlight, Enhanced Blood
10. **200s — Faithful gameplay/QoL**: BCR, Classic Holstered Weapons, companion fixes, cut content, survival helpers
11. **300s — Audio**: RAO, P.A.M.S, High-Fidelity Sounds, Ambient Wasteland
12. **900s — Patches that must win**: PRP patches for anything touching exteriors, LL/RAO weather patches

---

## Tier 1: Foundation & fixes (mandatory; test before anything else)

| # | Mod (Nexus) | Folder | Notes |
|---|---|---|---|
| 1 | **F4SE 0.7.9** (silverlock / 42147) | `001_f4se` → **game root** | Loader + `f4se_1_11_240.dll` + `Data/F4SE/`. Update the same day as any Steam patch. |
| 2 | **Address Library for F4SE Plugins – AIO** (47327) | `002_address_library` | Every DLL mod needs it; Addictol refuses to load without it. |
| 3 | **Addictol + Addictol Crash Logger** (84214) | `003_addictol` | The 2026 crash/memory layer: replaces Buffout 4/NG/AE, X-Cell, Baka ScrapHeap, Faster Workshop. Mutually exclusive with all of them. Linux note: if audio breaks, toggle the AudioSwitch (XAudio2.7) module in `Addictol.toml`. |
| 4 | **High FPS Physics Fix** (44798) | `004_high_fps_physics_fix` | The only allowed frame limiter. Config: `config/HighFPSPhysicsFix.ini`. Supersedes Long Loading Times Fix. |
| 5 | Hydra (104159) | `005_hydra` | Replaces Papyrus Common Library; install when a mod needs it. |
| 6 | Garden of Eden PSE (74160), Random Encounter Framework (60074) | `006_goe_pse`, `007_ref` | Libraries, as needed. |
| 7 | **Unofficial Fallout 4 Patch 2.2.1a** (4598) | `010_ufo4p` | Requires 1.11.221+ and all 15 DLC files. The consensus is *install it*; disagreements are handled by micro-revert mods, not by skipping it. |
| 8 | **Community Fixes Merged 4.6.x** (74945) | `011_community_fixes_merged` | On top of UFO4P. |
| 9 | TMR Glitchfinder AIO (74949) | `012_glitchfinder_aio` | |
| 10 | Sprint Stuttering Fix (47760) | `013_sprint_stuttering_fix` | Addictol 1.6 has a Sprint Stutter module; overlap unconfirmed, check `Addictol.log`. |
| 11 | Empty Vendor List Fix (83252), Magic Effect & Spell Engine Fixes (83433), Armor Penetration Bug Fix AE (73849), Follower AI Approach Reaction Fix (92024), Rain Bug Fix AE (106989) | `014`–`018` | Engine-bug DLL fixes, AE builds. |
| 12 | Wetness Shader Fix (23389), Fixed Gobo Effects (27445), Flutter Flicker Fixer – PRP file (79853), Motion Vector Fixes (98544) | `020`–`023` | Shader/asset fixes. Take the PRP variant of Flutter Flicker. |
| 13 | **Weapon Debris Crash Fix** (48078) | `024_weapon_debris_crash_fix` | Still needed on RTX in 2026; Addictol does not cover it. Belt-and-braces with `bNVFlexEnable=0`. |
| 14 | **Previsibines Repair Pack 81.9** (46403) | `030_prp` | Requires AE assets + latest UFO4P. Plugin loads last among world edits. Never with Boston FPS Fix. |
| 15 | RAW INPUT (27019) | `040_raw_input` | Optional. |

**Why this order**: engine → patches → shader fixes → PRP mirrors TMR's base section. UFO4P before CFM before PRP is a hard dependency chain (each builds on the previous).

### Tier 1 validation
- [ ] `F4SE/f4se.log` exists after launch; `Addictol.log` lists modules as applied
- [ ] Sanctuary → Concord → Diamond City → Boston Common without a crash
- [ ] FPS capped at refresh rate; drop a can, physics sane; Pip-Boy at 60
- [ ] No purple/missing textures, no floating grass at Sanctuary bridge (PRP working)
- [ ] `./check_setup.sh` = 0 errors

---

## Tier 2: Vanilla-plus visuals + UI

| # | Mod (Nexus) | Folder | Notes |
|---|---|---|---|
| 16 | **MCM** (21497, 1.11.240 build) | `100_mcm` | |
| 17 | HUDFramework (20309) | `101_hudframework` | |
| 18 | **FallUI – HUD** (51813) + Inventory, Map, Sleep and Wait, Confirm Boxes | `102_fallui_*` | Pure UI; supersedes DEF_UI. Skip Item Sorter tags if you want zero UI drift. |
| 19 | **XDI – Extended Dialogue Interface** (27216) | `103_xdi` | Full lines, no 4-option cap. Supersedes Full Dialogue Interface. |
| 20 | Crafting Highlight Fix (27479), Workshop Highlight Fix (83706) | `104`, `105` | |
| 21 | **Lightweight Lighting** (57680) | `110_lightweight_lighting` | TMR + FUSION's pick: vanilla+ weathers and interior lighting, no ENB, no perf cost. ELFX/UIL/NAC X not needed. |
| 22 | Gloomy Glass (62518) | `111_gloomy_glass` | |
| 23 | **Targeted Textures** (62958) | `120_targeted_textures` | Fixed, correctly sized vanilla textures. The most faithful base. |
| 24 | **Vivid Fallout – AIO 2K** (25714) *or* Luxor HD Overhaul 2K (65720) | `121_main_textures` | ONE main pack. Vivid (Apr 2026 update, NG-safe, lower VRAM) is the vanilla-faithful choice; Luxor is sharper and 43 GB. Pack loose textures to BA2 if you go big. |
| 25 | Fallout 4 HD Reworked Project (10467) | `122_hd_reworked` | Optional filler under the main pack. |
| 26 | Particle Patch (68599), **Enhanced Vanilla Water** (97214), Terrain Freckles Be Gone (99314), Sniper Scope Overlay Overhaul (101600) | `123`–`126` | TMR's small visual fixes. |
| 27 | Diamond City Billboards (71990), DC Supplements (75054), Goodneighbor View (72021) | `127`–`129` | PRP-safe as used in TMR. |
| 28 | **LOD set**: FO4LODGen Resources (80276) → FOLIP 8 (61884) → Far Harbor 3D Tree LODs (63191) → Optimized Vanilla Tree LODs (63198) → Northern Foothills Rocks Fix (70237) | `130`–`134` | FOLIP 8 replaces HD LOD Textures + ModernHouseLOD. Then generate Object LOD with xLODGen (Windows tool, run in the prefix) **or** install FOLIP's / TMR's pregenerated LOD into `135_generated_lod`. |
| 29 | Enhanced Blood Textures (212), Pip-Boy Flashlight (10840) | `140`, `141` | Optional. |
| 30 | Upscaling (99130) + This Made My Spline Stiff (98935) | `142_upscaling` | Optional DLAA replacement for TAA. **Linux unconfirmed**; needs `PROTON_ENABLE_NVAPI=1`. Try last. |

### Tier 2 validation
- [ ] MCM menu opens; FallUI HUD renders at native res
- [ ] Interiors readable (not pitch black) with LL; exteriors show new LOD on the skyline
- [ ] VRAM under ~12 GB at 1440p (MangoHud overlay for the check only, then remove its limiter)

---

## Tier 3: Faithful gameplay, QoL, audio

| # | Mod (Nexus) | Folder |
|---|---|---|
| 31 | Assorted Modular Tweaks – ESPless (84440) | `200_assorted_modular_tweaks` |
| 32 | **Bullet Counted Reload System** (41178) + lever-action file | `201_bcr` |
| 33 | **Classic Holstered Weapons** (46101) | `202_classic_holstered_weapons` |
| 34 | Remove Ammo from Dropped Guns (64426) | `203` |
| 35 | Remember Lockpick Angle NG/AE (96130) | `204` |
| 36 | Less Annoying Berry Mentats (11838), To Your Face (73259), Deadeye Weapon Effect Fix (57838), Simple Offence Suppression (75292) | `205`–`208` |
| 37 | Faster Workbench Exit (70013) | `209` |
| 38 | Dogmeat Lags Behind (107231), **Simple Everyone's Best Friend** (92314) | `210`, `211` |
| 39 | Integrated Addons (92016), Keep Radiants in the Commonwealth (56089), Encounter Zone Recalculation AE (99587) | `212`–`214` |
| 40 | Who's The General (59019 + patch hub 99080) | `215` |
| 41 | Cut content: Legendary Mutation Messages Fix (63929), Unused Map Markers (64009), Nuka World Cut Content Restored (106236), DLC Cut Content Restoration Project (29058) | `216`–`219` |
| 42 | Refreshing Checkpoints (102596), Molotov Nerf (15364) — optional | `220`, `221` |
| 43 | Place Everywhere (9424, 1.11.240 build) — optional, mild | `222` |
| 44 | Unlimited Survival Mode (26163), Safe Travels (102931) — survival only | `223`, `224` |
| 45 | **Reverb and Ambiance Overhaul** (10189) + weather patches | `300_rao` |
| 46 | P.A.M.S (1544) | `301_pams` |
| 47 | High-Fidelity Sounds Project (101798) — the literal "remaster" audio | `302` |
| 48 | Ambient Wasteland (25343) — optional | `303` |
| 49 | PRP patches for anything above that edits exteriors; RAO ↔ LL check in xEdit | `900_patches` |

---

## Deliberately skipped (strays or superseded)

- **Official HD Texture Pack DLC**: 58 GB, no visible gain, performance hit. Uncheck it in Steam.
- **Boston FPS Fix**: PRP's ancestor, incompatible with PRP.
- **Buffout 4 / NG / AE, X-Cell, Baka ScrapHeap, Faster Workshop**: folded into Addictol.
- **Long Loading Times Fix**: worse than HFPF configured per TMR.
- **DEF_UI / Full Dialogue Interface**: superseded by FallUI / XDI.
- **NAC X, Vivid Weathers, ELFX/UIL**: change the look or duplicate Lightweight Lighting.
- **Better Locational Damage, Immersive Gameplay, Lunar Fallout Overhaul, Sim Settlements 2, Better Settlers, Loot Logic, Complex Vendors, SPARS**: rebalance or replace systems.
- **The Fungal Forest**: new decoration, not cut content.
- **Commonwealth Warfare, Sound Pack Replacer, Immersive Fallout**: change the audio/gameplay identity.
- **ENB, PureDark DLSS/FG, Fallout 4 Vulkan Renderer**: non-functional or pointless under Proton.
- **A StoryWealth** (921-mod Vortex collection): a "more game" list built around Sim Settlements 2 and 25+ quest mods. Used here only as a source list for a future "more Commonwealth" stage.
- **Better Console, Console Autocomplete, PCL-dependent mods**: not strays, just unconfirmed for 1.11.240.

## Caution

This is the **folder layering order**; the **plugin load order** lives in
`loadorder.txt` and should be sorted with LOOT (Flatpak) then hand-checked:
UFO4P → CFM → everything else → PRP last, patches after PRP only when the patch
author says so.
