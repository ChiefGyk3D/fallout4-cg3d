# Research & Decision Record — September 2026

> **STATUS: TESTING — YMMV.** This is the "why" behind `FO4_BUILD_SHEET.md`.
> Every decision lists the alternatives considered, the evidence, the sources,
> and what could not be confirmed. Research ran 27 Sep 2026 from a sandbox where
> nexusmods.com, bethesda.net, reddit, ProtonDB and Steam guides were blocked;
> those were read through search-engine snippets, while GitHub/GitLab pages
> (F4SE tags, The Midnight Ride mirror, Addictol, MO2-LINT, Amethyst, Fluorine,
> LOOT, DepotDownloader, Proton) were read directly. Anything sourced only from
> a snippet is marked *(snippet)*.

## Goals (unchanged from morrowind-cg3d)

1. **Enhance the vanilla game, don't change it.** Fix bugs, modernize visuals
   and QoL, restore cut content. No rebalances, no system replacements, no
   total conversions, no lewd content.
2. **Use the hardware.** RTX 5070 Ti / 5950X / 64 GB should be visibly ahead of
   the stock Steam version, not just running it faster.
3. **Reproducible on Linux.** Numbered mod folders, scripts, a config checker,
   and docs good enough to rebuild from nothing. Same repo shape as Morrowind.
4. **Stream-night safe.** Version-locked, backed up, validated before launch.

## Current state (27 Sep 2026)

| Area | State |
|---|---|
| Research | Complete for the foundation and Tiers 1–3 (two parallel research passes, ~380k tokens of source reading) |
| Docs | README, build sheet, install order, mod list, tools reference, runbook, this record |
| Scripts | extract / deploy / check / backup written and tested end-to-end against **synthetic** archives, game root and prefix |
| Real machine | **Not yet run.** First prep night will validate the real archive layouts and the Proton launch path |
| Known unknowns | Listed at the bottom; none block Tier 1 |

---

## Decision 1 — Game version: stay on Steam 1.11.240

**Alternatives**: (a) stay current (1.11.240); (b) downgrade to "NG" 1.10.984; (c) downgrade to "OG" 1.10.163 (the 2019–2024 classic).

**Evidence**
- Timeline: 1.10.163 (2019–Apr 2024) → 1.10.980/984 "next-gen" (Apr/May 2024) → **1.11.137** "Creations Menu Update" pushed to all PC users with the Anniversary Edition (10 Nov 2025) → 1.11.159, .169, .191 (Dec 2025) → **1.11.221** (27 May 2026) → **1.11.240** (18 Aug 2026; raised the BA2 limit 256 → 1024). *(snippets: Nexus news 15400, comicbook, univers-simu)*
- F4SE tags on github.com/ianpatt/f4se: 0.7.9 = 16 Aug 2026 for 1.11.240; F4SE has shipped within ~2 days of every patch since Nov 2025.
- Core F4SE mods with 1.11.240 builds *(snippets of their Nexus pages)*: Address Library AIO (21 Aug), High FPS Physics Fix (8 Sep), MCM (1 Sep), Place Everywhere (22 Aug). Addictol supports all three lines from one DLL (README read directly).
- **The Midnight Ride** changelog (raw GitHub mirror): moved to NG exe 10 Oct 2025, back to OG 23 Dec 2025 "to buy time", then **22 Jul 2026: "The guide now uses 1.11.221, meaning no downgrade is needed"** and removed its downgrader.
- The fix spine now *requires* AE data: UFO4P 2.2.x needs 1.11.221+ and all 15 DLC files; PRP 81.x needs "AE assets (1.11.221+)". Downgrading to 1.10.163 would mean old UFO4P/PRP builds.

**Decision**: (a). Downgrading is now only for people locked to abandoned DLL mods.
**Cost**: a hold-out window after each Bethesda patch → mitigated by the manifest lock (Decision 2).
**Unconfirmed**: whether TMR itself has moved from 1.11.221 to 1.11.240 (its changelog stops at 26 Jul 2026); Baka ScrapHeap/Workshop Framework 1.11.240 builds (moot: not used / Papyrus-only).

## Decision 2 — Version lock

**Alternatives**: Steam's "only update when I launch" (soft lock, still updates on launch); read-only `appmanifest_377160.acf` (hard lock); DepotDownloader rollback kit.
**Decision**: all three, layered: soft lock + `chmod a-w` on the manifest + a copy of the vanilla exe/`steam_api64.dll` + DepotDownloader-linux-x64 3.4.0 on hand.
**Unconfirmed**: Windows reports say Steam refuses to *launch* while the manifest is read-only; not verified on Linux. If so: unlock, launch, re-lock.

## Decision 3 — Crash/memory layer: Addictol

**Alternatives**: Buffout 4 (1.10.163 only); Buffout 4 NG (page states no Anniversary support *(snippet)*); Buffout 4 AE / MiniBuff (1.7.1, "no longer in development; future fixes in Addictol"); X-Cell (archived Jan 2026, redirects to Addictol); Baka ScrapHeap (last build for 1.11.159).
**Evidence**: Addictol README (read directly): one DLL, 94 modules (memory allocator, crash logger with .240 PDB support, archive/handle limits, Papyrus GC, navmesh, facegen, faster workshop), hard-requires Address Library, supports OG/NG/AE. TMR replaced Buffout 4 NG with it on 4 Mar 2025.
**Decision**: Addictol + Addictol Crash Logger. Nothing it replaces may coexist with it; `check_setup.sh` errors if Buffout/ScrapHeap/X-Cell DLLs are present.
**Unconfirmed**: Proton behaviour (README says Windows x64 only, silent on Wine; MiniBuff's Linux note about InteriorNavCut multithreading and CreateD3DAndSwapChain may apply). Whether Sprint Stuttering Fix / Armor Penetration Fix / Moon Rotation Fix duplicate Addictol 1.6–1.7 modules.

## Decision 4 — Frame limiter: High FPS Physics Fix only

**Evidence**: FO4 physics and loading are frame-tied; HFPF switches caps dynamically (in-game / Pip-Boy / loading screens) which external limiters cannot. TMR: "do not use any external limiter". HFPF's Sept 2026 build lists 1.11.240. Long Loading Times Fix is superseded (TMR FAQ: "has its own set of issues and performs worse"). The separate "High FPS Fix" (107877) and "Physics Fixes" (107879) mods are incompatible with HFPF; TMR still uses HFPF.
**Decision**: HFPF with TMR's settings (`config/HighFPSPhysicsFix.ini`); no MangoHud/DXVK limiter.

## Decision 5 — Patch spine: UFO4P → Community Fixes Merged → PRP

**The UFO4P "debate"**: some UFO4P fixes are arguably design changes (Unyielding/Martyr chest-only, Nukalurk egg removal). The community's answer is *micro-revert* mods (e.g. "UFO4P Reverts – Unyielding", 82979), **not** a "UFO4P-minus" package; no maintained one exists. Every current vanilla-plus list (TMR, FUSION, WTP, LitR) installs UFO4P. CFM "expects a patched setup, no support without UFO4P". *(afkmods version history, STEP forum)*
**PRP vs Boston FPS Fix**: Boston FPS Fix is PRP's ancestor; incompatible. PRP 81.9 (7 Sep 2026) requires AE assets + latest UFO4P; loads last among world edits; any mod editing exteriors needs a PRP patch (patch hubs: 102143, 95644).
**Decision**: install all three, in that order; PRP plugin last.

## Decision 6 — Mod manager: this repo's scripts (deploy_mods.sh)

**Alternatives evaluated** (state as of Sept 2026):

| Option | State | Verdict |
|---|---|---|
| MO2 via **MO2-LINT 7.0.0** (Furglitch fork of rockerbacon's installer) | Released 23 Sep 2026; installs MO2 2.5.2 as a Steam compat tool, bundles protontricks, requires Proton 11 ("Fallout 4 no longer works with Proton 9") | Community standard; the only manager TMR supports. Optional GUI here. |
| **Amethyst Mod Manager** | v2.5.x (18–27 Sep 2026); native Qt, MO2-style, libloot, FOMOD, VFS deploy | Strongest native alternative; TMR's FAQ points here |
| **Fluorine Manager** | 0.3.4 (5 Sep 2026); MO2 port with FUSE VFS; author: "primarily for personal use" | Promising, early |
| Limo | last release/commit 3 May 2025 | Dormant |
| Nexus Mods App | retired Jan 2026, repo archived Feb 2026; FO4 never left "in development" | Dead |
| Vortex on Linux | native version promised for 2026, not shipped; Wine gists unsupported | Skip |
| Manual (Data + plugins.txt) | every Linux guide: "the less painful route" | **Chosen**, scripted |

**Decision**: numbered folders → symlinks into `Data/` (F4SE to the game root), manifest for clean removal, `plugins.txt` generated from `loadorder.txt`, LOOT Flatpak 0.29.2 for sorting. Reason: reproducibility and the same workflow as the Morrowind repo. FOMODs: extractor copies core folders and lists optional ones; no maintained CLI FOMOD installer for Linux was found.

## Decision 7 — Proton 11.0-2, launch via `%command%` substitution

**Evidence**: Proton 11.0-2 (21 Aug 2026) is Valve stable; GE-Proton11-7 (16 Sep 2026) adds NVAPI/CUDA libs. MO2-LINT dropped Proton 9 for FO4. Launch line `bash -c 'exec "${@/Fallout4Launcher.exe/f4se_loader.exe}"' -- %command%` is the standard F4SE-in-Proton trick (alternatives: rename loader; `protontricks-launch`).
**Unconfirmed**: the claim that GE-Proton auto-launches F4SE (no protonfix for 377160 found); HBAO+ correctness under DXVK.

## Decision 8 — GPU specifics for a 5070 Ti

- **Weapon Debris off** (`[NVFlex] bNVFlexEnable=0`) + Weapon Debris Crash Fix: NVIDIA FleX crashes on every Turing-and-later GPU; Addictol does not cover it. Under Proton the fix reportedly stops crashes but debris doesn't collide *(RTX 3060 report, snippet)*. FlexRevive (108006) is untested on Linux.
- **NVIDIA open kernel modules 570+**: the proprietary branch has no Blackwell support.
- **Official HD Texture Pack DLC not installed**: 58 GB, "barely makes the game look better, nosedives performance"; TMR requires it absent *(Windows Central)*.
- **Upscaling/frame-gen**: PureDark's DLSS/FG are paid Windows DLLs; the open-source "Upscaling" (99130) offers DLSS 4/FSR 3.1/DLAA (upscaling only) and needs NVAPI under Proton — **Linux unconfirmed**, tried last, DLAA-only. Frame generation on Linux is unreliable; skipped. A 5070 Ti runs FO4 at native resolution anyway.
- **VRAM budget (16 GB @1440p)**: Vivid 2K + Targeted Textures + FOLIP LOD + Lightweight Lighting ≈ 6–8 GB; Luxor 2K stack ≈ 10–11 GB; leave 2–3 GB for DXVK staging.

## Decision 9 — Visual direction: "remaster" packs only

- **Lighting**: Lightweight Lighting (TMR + FUSION's pick; vanilla+ weathers and interiors, no ENB, no perf cost). ELFX/UIL duplicate it and conflict with each other without a merge patch; NAC X and Vivid Weathers change the look.
- **Textures**: Targeted Textures (fixed, correctly sized vanilla) + ONE main pack: Vivid Fallout AIO 2K (Apr 2026, NG-safe, lower VRAM) by default, Luxor 2K as the sharper alternative. Loose textures should be packed to BA2 if the set grows (TMR FAQ).
- **LOD**: FOLIP 8 (Aug 2026, replaces HD LOD Textures + ModernHouseLOD) + FO4LODGen Resources + tree/rock companions, then generated Object LOD (xLODGen in the prefix) or FOLIP's/TMR's pregenerated package.
- **UI**: FallUI family + XDI (supersede DEF_UI and Full Dialogue Interface); MCM 1.11.240 build.
- **ENB**: not needed and unreliable under Proton; ReShade via reshade-steam-proton or vkBasalt if wanted.

## Decision 10 — Gameplay: TMR "Extended" faithful subset; everything else skipped

Kept: BCR, Classic Holstered Weapons, Remove Ammo from Dropped Guns, Remember Lockpick Angle, Simple Everyone's Best Friend, Dogmeat Lags Behind, Integrated Addons, Keep Radiants in the Commonwealth, Encounter Zone Recalculation, Who's The General, cut-content restorations, survival helpers. Audio: RAO, P.A.M.S, High-Fidelity Sounds Project (restores FO4 SFX from the higher-quality PS4 audio, the most literal "remaster" audio mod).
Skipped as strays: Better Locational Damage, Immersive Gameplay, Lunar Fallout Overhaul, Sim Settlements 2, Better Settlers, Loot Logic & Reduction, Complex Vendors, SPARS, Legendaries They Can Use, The Fungal Forest (not cut content), Commonwealth Warfare, Sound Pack Replacer.
**A StoryWealth** (921-mod Vortex collection; 25+ quest mods, SS2 + Chapter 3): a "more game" list, Vortex-only. Kept as a *source list* for a future "more Commonwealth" stage.

## Curated guides consulted

| Guide | Status | Used for |
|---|---|---|
| The Midnight Ride (ModdingLinked) | Active; 1.11.221 as of 26 Jul 2026; MO2-only; "Linux support planned but not near" | Primary vanilla-plus reference; base + Extended sections |
| FUSION (Wabbajack, SpringHeelJon) | Active; modlist public on GitHub | Heavier vanilla-plus visual pass |
| Welcome to Paradise (Wabbajack) | Last updated Sep 2023 (pre-NG) | Ideas only |
| Life in the Ruins (Wabbajack) | Active but built on Lunar Fallout Overhaul | Strays; not used |
| BiRaitBec | Unmaintained; continuation on a Discord | Not a 2026 source |
| A StoryWealth (Nexus collection) | Active; 921 mods | Future source list only |

## Could not confirm (verify on prep night)

1. Real archive layouts of every Nexus mod (extractor heuristics are tested on synthetic archives only).
2. Addictol under Proton; Addictol AudioSwitch vs the Wine `xact_64` / `xaudio2_7` audio fix.
3. Whether a read-only appmanifest blocks launching on Linux Steam.
4. TMR's position on 1.11.240; exact current Addictol version on Nexus vs GitHub (1.7.0).
5. "Upscaling" (99130) under Proton; HBAO+ under DXVK.
6. Better Console / Console Autocomplete / PCL-dependent mods on 1.11.240 (left out for now).
7. RAO ↔ Lightweight Lighting record conflicts (both touch weather; check in xEdit).
8. AE status of the ESP-only QoL mods (Quick Trade, Companion Command, Settlement Menu Manager, iHUD, Faster Terminal Displays) — no DLLs, expected fine.
9. Luxor's VRAM figures (mod page claims, not measured).

## Sources (reachable directly)

github.com/ianpatt/f4se/tags · github.com/ModdingLinked/The-Midnight-Ride (changelog, intro, utilities, faq, mo2, setup, lod) · github.com/Dear-Modding-FO4/Addictol · github.com/AntoniX35/High-FPS-Physics-Fix · github.com/Furglitch/modorganizer2-linux-installer · github.com/ChrisDKN/Amethyst-Mod-Manager · github.com/SulfurNitride/Fluorine-Manager · github.com/limo-app/limo · github.com/Nexus-Mods/NexusMods.App · github.com/loot/loot/tags · github.com/SteamRE/DepotDownloader · github.com/ValveSoftware/Proton/tags · github.com/GloriousEggroll/proton-ge-custom · github.com/SpringHeelJon/FO4-FUSION · github.com/wabbajack-tools/mod-lists · github.com/reg2k/xdi · github.com/TheGamerX20/MiniBuffAE · github.com/ValveSoftware/steam-for-linux/issues/12094 · github.com/kevinlekiller/reshade-steam-proton

## Sources (snippet-only; pages blocked from the sandbox)

nexusmods.com mods 42147, 47327, 44798, 84214, 4598, 74945, 46403, 61884, 57680, 62958, 25714, 65720, 21497, 27216, 9424, 48078, 99130, 108006 and news 15400 · f4se.silverlock.org · steamdb.info/patchnotes/20686861 · afkmods.com UFO4P version history · stepmodifications.org (CFM thread, PRP wiki, FOLIP wiki) · steamcommunity.com guides 3625329062, 2807798803 and discussions on versions, Proton, F4SE audio · windowscentral.com (HD texture pack) · univers-simu.com / comicbook.com (1.11.240) · gamingonlinux.com (Nexus app retirement, Vortex pledge) · bbs.archlinux.org (F4SE audio) · paulkmiller.com (StoryWealth on Deck)
