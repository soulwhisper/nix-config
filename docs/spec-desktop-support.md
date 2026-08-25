# Spec: NixOS Desktop Support

Status: **modules implemented and eval-verified** (2026-08-25). Claims grounded against pinned sources (nixpkgs `26.05beta1.705e992` = search.nixos.org index `a9e6d84f`, HM release-26.05). Decisions resolved per owner review — see §7. **Update 2026-08-25 (2): `hyprland` environment added (end-4 illogical-impulse Quickshell shell) and made the default; niri kept as secondary. See §9.**

## 1. Current State

### Import graph (verified)

```
mkNixosSystem (lib/mkSystem.nix)
├── hosts/_modules/common
├── hosts/_modules/nixos        ← shared by every NixOS host, namespace `modules.*`
│   ├── filesystems/{xfs,zfs}
│   ├── hardware/nvidia         ← defined, enabled by NO host today
│   ├── services/*              ← 27 services, opt-in via `modules.services.<name>.enable`
│   ├── secrets, nix.nix, users.nix
└── hosts/<hostname>
```

Current hosts `nix-infra`, `nix-ops`: headless ESXi VMs. Baseline health proven by eval:

- `nix-infra` → `g39iwgp2h9aq5xq03fmw3xp8abjla9iq-nixos-system-nix-infra-26.05....drv`
- `nix-ops` → `n3hl7n28c72mmqbpk9v95hd7dd53js87-nixos-system-nix-ops-26.05....drv`

(Both emit a pre-existing HM warning: `programs.gemini-cli` renamed to `programs.antigravity-cli`. Out of scope here.)

### Left work #1: `hosts/_modules/nixos/hardware/nvidia/default.nix`

Enabled by zero hosts; last real consumer was deleted host `nix-dev`. Problems:

| # | Issue | Why wrong |
|---|-------|-----------|
| 1 | `services.lact.enable = true` unconditional | LACT is a GUI GPU-control daemon; dead weight under `driverType = "datacenter"` |
| 2 | `hardware.graphics.enable32Bit = true` unconditional | pulls i686 driver stack on compute nodes; only Steam/Wine-class apps need it |
| 3 | `nvidia-container-toolkit.enable = true` unconditional | only meaningful with podman/docker CUDA containers; should be policy, not axiom |
| 4 | `boot.kernelParams = ["nvidia-drm.fbdev=1"]` unconditional | fbdev/modeset is a Wayland-desktop concern; noise on headless |
| 5 | `open = false` hardcoded | upstream asserts explicit choice for driver ≥ 560; open modules recommended for Turing+ |
| 6 | No passthrough for PRIME offload / dynamic boost | blocks any future hybrid laptop |

### Left work #2: desktop module

Absent from `_modules/nixos` entirely. Prior art lives in `.archived/desktop/` (disabled Sep 2025, commit `b4e8027` "until upstream fixed"):

- `kde/` — plasma6 + sddm-wayland: complete, proven
- `hyprland/` — literal stub: `# ! not finished yet !`, note says prefer **niri** over raw Hyprland
- `peripherals.nix` — pipewire/bluetooth/power(printing/geoclue/android-udev): complete
- `applications/` — app set + fcitx5/rime input method: complete
- `fhs/` — buildFHSEnv + nix-ld libs: complete (base `programs.nix-ld` already on in `_modules/nixos`)
- `gaming/` — steam/gamemode/gamescope + pipewire lowlatency + sysctl optimizations: complete

Old flat option surface (`modules.desktop.{enable,manager}`) predates the current `modules.<category>.<name>` convention.

### Home-manager side is already prepared

`homes/_modules/customization/default.nix` writes Ghostty config to XDG path and Rime config to `~/.local/share/fcitx5/rime` unconditionally — the Linux input-method path exists, only the NixOS-side fcitx5 plumbing is missing.

## 2. Upstream Facts (pinned nixpkgs 26.05)

NVIDIA (`nixos/modules/hardware/video/nvidia.nix`):

- Activation is driven by `"nvidia" ∈ services.xserver.videoDrivers`; `hardware.nvidia.datacenter.enable` is the separate NVLink/compute path.
- Assertion: X11-nvidia and datacenter drivers are mutually exclusive.
- `hardware.nvidia.open` type `nullOr bool`, defaults to `null` on driver ≥ 560, assertion demands an explicit value.
- `branch` auto-defaults to `stable` (graphics) / `dc` (datacenter) — no need to re-expose package selection.
- New knobs worth adopting: `dynamicBoost.enable` (laptops), `moduleParams`, suspend notifiers (≥595 + open modules).

Verified present: `services.desktopManager.plasma6` (+auto-wired sddm), display managers greetd/ly/sddm, `programs.hyprland`, `programs.wayland.niri`, `programs.steam` (`gamescopeSession`, `extest.enable`, `fontPackages`), `programs.gamemode`, `programs.clash-verge` (`enable`, `autoStart`), `i18n.inputMethod.fcitx5.waylandFrontend/addons`, `services.lact.settings`, `services.auto-cpufreq.settings`, `programs.nm-applet`, fonts `lxgw-neoxihei` / `nerd-fonts` / `wqy_zenhei`.

Base-module conflicts discovered:

1. `hosts/_modules/nixos/default.nix` plain-sets `networking.useNetworkd = true` and `systemd.network.enable = true` for **all** hosts. A second plain definition differs → hard merge conflict. Desktop must either `mkForce` or the base must move to `lib.mkDefault` (preferred: one-line layering fix, zero behavior change for servers).
2. Same file default-enables `modules.services.mihomo` (subscription via sops) on every host — a desktop may want the `clash-verge` GUI instead; needs an explicit decision (§7).

## 3. Environment Evaluation: KDE vs Hyprland vs niri

Method: three identical-base `lib.eval-config` systems differing only in the DE stack (`/tmp/de-bench`, eval-only — nothing built). Closure diff via `.drv` requisites (`nix-store -qR`); system-package diff via `config.environment.systemPackages`.

| Metric | KDE Plasma 6 + SDDM | Hyprland 0.55.4 | niri 26.04 |
|---|---|---|---|
| toplevel drv closure | **8110** drvs | 6140 drvs | 6127 drvs |
| `environment.systemPackages` | **199** | 86 | 86 |
| unique adds over bare base | full Plasma/KDE Gear stack | exactly `hyprland` + `xdg-desktop-portal-hyprland` | compositor set incl. xwayland |

Reading:

- **KDE is a complete DE as an option value.** One flag pulls kwin/plasma-workspace/dolphin/konsole/spectacle/kwallet(+pam)/powerdevil/portals/polkit agent, **plus laptop-relevant pieces for free**: `fwupd`, `udisks`, `upower`, `geoclue2`, `power-profiles-daemon`. Cost: ~32% more derivations than the compositors.
- **Hyprland/niri are compositors only.** The NixOS modules wire portal + session; bar/launcher/idle/lock/wallpaper/notification daemon are all user-supplied (waybar, fuzzel, hypridle/hyprlock or swayidle/swaylock, mako...). Expect ~5 extra components to choose, wire, and maintain per environment module.
- **NVIDIA dimension:** KWin Wayland on proprietary driver is mature/boring. Hyprland's own wiki (updated 2026‑08‑22): *"should run just fine on Nvidia"* but with a dedicated caveat page and mandatory env setup (`GBM_BACKEND=nvidia`, `__GLX_VENDOR_LIBRARY_NAME=nvidia`, `LIBVA_DRIVER_NAME=nvidia`, cursor/flicker caveats). niri (smithay-based) works but is less battle-tested on proprietary driver. Our target hardware class includes NVIDIA GPUs → this matters.
- **NixOS module maturity:** plasma6 module = whole-DE integration maintained in-tree; hyprland/niri modules = thin wrappers. On NixOS specifically, KDE has fewer moving parts to pin.

Verdict at spec time: KDE default on reliability/NVIDIA grounds. **Owner decision overrode this: niri chosen** (see §7) — accepted trade-off: more session-companion wiring, thinner NVIDIA track record.

## 4. Notebook / Unfamiliar-Hardware Handling

"Unfamiliar hardware" = whatever the next notebook turns out to be. Strategy in four layers:

### L1 — Generic laptop profile (new `modules.hardware.laptop`)

Verified upstream facts that make this non-optional:

| Option | Default in pinned tree | Consequence if unset |
|---|---|---|
| `hardware.enableRedistributableFirmware` | **false** (follows `enableAllFirmware=false`) | no linux-firmware → Wi-Fi/BT dead on most laptops |
| `hardware.cpu.intel.updateMicrocode` / `amd.updateMicrocode` | **false** | no CPU microcode updates |
| `hardware.sensor.iio.enable` | false | no auto screen rotation/tablet mode |

Proposed surface (hardware concern → lives under `hardware/`, not `desktop/`):

```nix
modules.hardware.laptop = {
  enable      = mkEnable;
  fingerprint = mkEnable;   # services.fprintd (+ .tod driver hook), default off
};
# when enable:
#   hardware.enableRedistributableFirmware = true; cpu microcode = true (vendor-detected)
#   services.thermald.enable (Intel) ; services.auto-cpufreq with battery/charger profiles
#   brightnessctl ; hardware.sensor.iio.enable ; logind HandleLidSwitch=suspend
```

Note: KDE already brings `power-profiles-daemon`; auto-cpufreq conflicts with it (archived peripherals did `mkForce false` on ppd). Rule: `laptop.enable` switches to auto-cpufreq and disables ppd; plain desktops keep ppd.

### L2 — Hybrid GPU wiring (`modules.hardware.nvidia.prime.*`)

Options verified live on search.nixos.org (channel 26.05): `prime.offload.enable`, `prime.offload.enableOffloadCmd`, `prime.sync.enable`, `prime.reverseSync.enable`, `prime.{intelBusId,amdgpuBusId,nvidiaBusId}`, plus `dynamicBoost.enable`. The rewritten nvidia module passes this group through (graphics profile only) and defaults `dynamicBoost.enable` on when `laptop.enable && profile == "graphics"`.

### L3 — Model-specific quirks: adopt `nixos-hardware`

The canonical answer to "unfamiliar notebook" is [nixos-hardware](https://github.com/NixOS/nixos-hardware) (per-model modules: firmware, kernel params, EDID quirks, fan control). Plan: add `inputs.nixos-hardware.url = "github:NIXOS/nixos-hardware/master"` to flake inputs; each host imports its model module from `hosts/<hostname>/default.nix` (e.g. `nixos-hardware.nixosModules.lenovo-thinkpad-x1-...`). No shared-module coupling; servers simply don't import one.

### L4 — First-boot discovery workflow for unknown machines

1. Boot NixOS installer ISO → `nixos-generate-config` skeleton, then `inxi -Fzxxx` / `hw-probe -all -upload` for the device inventory (GPU pair, Wi-Fi/BT chipset, sensor HID).
2. Map findings: dGPU present? → L2 PRIME busIds. Odd Wi-Fi/BT? → check `linux-firmware` coverage vs `enableAllFirmware` (unfree). Exotic touchpad/panel? → search nixos-hardware for the model first.
3. Only then write `hosts/<name>/{hardware-configuration,disko}.nix`.

## 5. Proposed Design

### 5.1 `modules.hardware.nvidia` — rewrite

```nix
modules.hardware.nvidia = {
  enable    = mkEnable;
  profile   = enum [ "graphics" "compute" ] "graphics";  # replaces driverType
  openKernelModules = bool // { default = true; };       # Turing+ recommendation; assert-guarded
  containerToolkit  = bool // { default = profile == "compute"; };
  prime = {
    offload.enable = mkEnable;              # hybrid notebook default path
    sync.enable    = mkEnable;              # mutually exclusive with offload (assert upstream)
    intelBusId / amdgpuBusId / nvidiaBusId = str;   # required when either prime mode on
  };
};
# dynamicBoost.enable defaults true when modules.hardware.laptop.enable && profile=="graphics"
```

Mode matrix:

| Setting | `graphics` | `compute` |
|---|---|---|
| `services.xserver.videoDrivers += nvidia` | yes | no |
| `hardware.nvidia.datacenter.enable` | no | yes |
| modesetting / `nvidia-drm.fbdev=1` kernelParam | yes | no |
| `services.lact` | `mkDefault true` (opt-out flag) | no |
| `graphics.enable32Bit` | exposed as `graphics32Bit` flag, default false | no |
| `nvidiaPersistenced` | false | true |
| container toolkit | per flag | per flag |

Kept as direct passthrough (no re-exposure): `powerManagement.*`, `nvidiaSettings`, `package`/`branch` (upstream auto-selects). `openKernelModules` maps onto `hardware.nvidia.open`.

### 5.2 New `hosts/_modules/nixos/desktop/` — mode-based tree

Follows the `services/` convention (one dir per concern, aggregator imports children):

```
desktop/
├── default.nix        # options + import list
├── base.nix           # DE-agnostic plumbing
├── environments/kde.nix
├── environments/niri.nix
├── input-method.nix   # fcitx5 + rime (HM side already ships rime-moqi-yinxing)
├── applications.nix   # ported from .archived, pruned
├── fhs.nix            # ported verbatim-ish
├── gaming.nix         # ported incl. pipewire lowlatency + sysctl
```

Option surface:

```nix
modules.desktop = {
  enable      = mkEnable;                    # base.nix scope only
  environment = enum [ "kde" "niri" ];       # session choice
  gaming.enable = mkEnable;                  # implies nvidia.graphics32Bit + ppd-off rule
};
# laptop power/sensor/firmware handling lives in modules.hardware.laptop (§4 L1)
```

`base.nix` (every desktop, regardless of environment): pipewire stack (alsa/pulse/jack/wireplumber + rtkit), bluetooth + blueman, NetworkManager (+ `nm-applet` only under niri), fwupd, udisks2/gvfs, xdg portals, CJK + nerd fonts (`lxgw-neoxihei`, `nerd-fonts.jetbrains-mono`), android-udev, printing/geoclue2, user-group wiring, `networking.useNetworkd = lib.mkForce false` (after §2 fix: plain override wins over base `mkDefault`).

Environment modules:

- `kde.nix`: plasma6 + sddm-wayland + kdePackages extras (fcitx5-configtool, partition-manager).
- `niri.nix`: `programs.niri` + greetd (tuigreet) + waybar/mako/swaylock-class utilities + fcitx5 waylandFrontend. Replaces the abandoned Hyprland stub per the archived note.

Cross-module contracts:

1. `desktop.gaming` sets `modules.hardware.nvidia.graphics32Bit = mkDefault true` (guarded on nvidia enable) — no reverse dependency.
2. `desktop.gaming` sets `services.pipewire` lowlatency configs via `extraConfig` (merge-safe with base).
3. `users.nix`: extend the existing `ifGroupsExist [...]` candidate list with `networkmanager`, `input`, `lp` — guarded pattern means zero effect on servers. `video`/`audio` membership added by `desktop/base.nix`.
4. No `mkForce` anywhere except the two networkd flags (and only after base moves to `mkDefault`).

### 5.3 What gets dropped

- `.archived/desktop/hyprland/` stub — superseded by `environments/niri.nix`; never functioned.
- Old flat `options.modules.desktop` shape — replaced by namespaced options above.
- `ticktick`, `vmware-workstation`, `dropbox` from the archived app list unless re-requested (dead/unmaintained upstreams; decide at review).

## 6. Verification Plan

1. Regression: `nix eval` toplevel drv of `nix-infra`, `nix-ops` — must stay byte-identical class (no new derivations pulled into server closures).
2. Integration: throwaway `lib.nixosSystem` harness (not committed) enabling `desktop+niri+nvidia+gaming`, plus a prime-offload variant and a bad-prime negative — proves assertions (prime exclusivity, busId requirements, 32-bit x86_64 check) and the option graph merge.
3. `just lint` (prek) on touched files.
4. Smoke on real surface: `nixos-rebuild build-vm --flake .#<host>` for a graphical boot check (greetd→niri session); compositor interaction itself is eval-verified only until real hardware exists.

## 7. Decisions (resolved 2026-08-25)

1. **Environment**: ~~niri preferred~~ superseded 2026-08-25: `hyprland` (illogical-impulse) is the default; niri kept as secondary — see §9.
2. **NVIDIA scope**: datacenter/compute mode removed entirely. Module is gaming-focused; local compute will run in containers, so `nvidia-container-toolkit` stays on by default (`containerToolkit` flag).
3. **Host**: notebook host will be named `hosts/nix-dev` (weak GPU; PRIME offload path ready). Scaffold deferred to a follow-up commit.
4. **Proxy / gaming / nixos-hardware input**: unchanged from spec defaults (mihomo base kept; gaming included in v1; `nixos-hardware` input added when the host lands).


## 8. Implementation Status

| Piece | State | Proof |
|---|---|---|
| `hardware/nvidia/default.nix` rewrite | done | eval passes; bad-prime variant fails with expected assertions |
| `_modules/nixos/default.nix`: `mkDefault` networkd layering + desktop import | done | server regression drvs byte-identical |
| `desktop/{base,environments/niri,input-method,applications,fhs,gaming}` | done | full-graph harness evals clean incl. HM/sops/catppuccin |
| Regression `nix-infra`/`nix-ops` | pass | drv hashes unchanged: `g39iwgp2…`, `n3hl7n28c…` |
| Feature harness (desktop+niri+gaming+nvidia) | pass | `rhwqp86f…`; prime offload variant `8gnrw3p7…` |
| Negative test (offload+sync together) | pass | fails with module + upstream assertions as designed |
| Networking override | verified | `useNetworkd=false`, NetworkManager=true, groups merged |
| Lint (nixfmt + hooks) on touched files | pass | prek scoped run green |

Deferred to host-scaffold commit: `hosts/nix-dev/` skeleton (disko/zfs or xfs, secrets), `nixos-hardware` flake input, real-machine smoke.

## 9. Hyprland / illogical-impulse Environment (implemented 2026-08-25)

Owner decision: adopt end-4/dots-hyprland main (Quickshell generation) as a full desktop, rewritten into this repo's module style; it replaces niri as the default environment.

### Conflict policy (applied)

| Class | Ruling | Examples |
|---|---|---|
| Apps conflicting with ours | **ours win** | terminal = ghostty (ii chains rewritten via their own `custom/variables.lua` override point), shell stack (fish/starship/atuin), input method (fcitx5+rime, ours), browser (chrome — already first in ii's launch chain), thorium/dropbox-class apps dropped |
| Conflicts with heavy ii-look impact | **theirs win** | fuzzel config, matugen + kde-material-you-colors theming pipeline, Kvantum/darkly/kdeglobals Qt theming, bibata cursors, ii font set (rubik, material symbols), mpv |
| Neutral | theirs, additive | cliphist, swappy, wf-recorder, tesseract, songrec, translate-shell, libqalculate, cava, playerctl, easyeffects, ydotool, ddcutil |

### Wiring

- Flake input: `dots-hyprland` (`flake = false`) as the config source tree — updates = bump lock together with upstream.
- Quickshell: **follows nixpkgs** (`pkgs.quickshell` v0.3.0 ⊇ ii's supported pin; see rev audit below) — no flake input.
- `modules.desktop.environment = "hyprland"` (new default) | `"niri"` (kept).

### Quickshell rev audit (2026-08-25)

- ii packaging pins two revs that disagree: ARCH PKGBUILD `7511545e` (2026-03-19, actively maintained) vs dist-nix flake.lock `db1777c2` (2025-10, stale lock). Effective upstream support = `7511545e`.
- nixpkgs `quickshell` v0.3.0 (2026-05-04) strictly contains `7511545e` (0 behind); all 77 upstream commits since the pin are additive/fixes — no breaking QML API changes.
- Per repo policy (follow upstream unless a hard dependency): **use `pkgs.quickshell`**, no flake input. Fallback documented in-module: re-pin `7511545e` if a nixpkgs bump breaks ii QML.
- QML ground-truth deps found and wired: Kirigami (8 imports → quickshell wrapped via symlinkJoin with `kdePackages.kirigami`), `magick` (8 refs → imagemagick), `kdialog` (1 ref). `wlogout` has **zero** references in the Quickshell generation (AGS-era leftover) → config deployment dropped. `libdbusmenu-gtk3` not needed (quickshell implements StatusNotifier natively).

### Full ii package disposition (deps-info.md, all 234 lines)

Kept (look/style/taste — complete): matugen + kde-material-you-colors pipeline, Kvantum, darkly, kdeglobals/konsolerc/dolphinrc, fuzzel configs, bibata cursors, adw-gtk3, breeze+breeze-icons, fonts rubik/material-symbols/twemoji/jetbrains-mono (+base lxgw/nerd/emoji), hypr config tree incl. custom scaffold, quickshell/ii shell, mpv, chrome-flags/code-flags.

Kept (new apps — pending owner judgment): easyeffects, songrec, translate-shell, swappy, wf-recorder, hyprshot, slurp, tesseract, cava, playerctl, pavucontrol-qt, cliphist, libqalculate, hypridle/hyprlock/hyprpicker/hyprsunset, ydotool, wtype, ddcutil, brightnessctl, upower, geoclue2(+demo agent), dolphin, systemsettings, bluedevil, plasma-nm, kdialog, btop, imagemagick, glib, jq, bc, wget, xdg-user-dirs, fuzzel, foot+kitty (deep-fallback binaries only).

Dropped (with reason): fish/zshrc.d/starship.toml configs (our shell stack), kitty/foot configs (ghostty default), fontconfig conf (HM owns path), thorium-flags (not our browser), wlogout (unused by shell), cmake/clang/rsync/go-yq (installer/build-time only), uv+venv (replaced by nix python env), gtk4/libadwaita/libsoup/libportal (venv build deps, unneeded), polkit-kde-agent (shell ships its own agent; upstream dist-nix also skips), libdbusmenu-gtk3 (SNI native in quickshell), breeze-plus/space-grotesk/readex-pro/MicroTeX (absent from nixpkgs — accepted gaps), tesseract-data-eng (bundled in nixpkgs tesseract).

### Remaining known gaps

- `MicroTeX` (LaTeX widget), fonts `space-grotesk`/`readex-pro`, `breeze-plus`: absent from nixpkgs — features degrade or fall back.
- ii's `fontconfig/fonts.conf` not deployed (HM owns `~/.config/fontconfig`); font fallback order may differ slightly.
- Real-machine smoke pending (eval-verified only; nixpkgs quickshell 0.3.0 supersedes ii's 0.2.0-era pin).

### pfaj/nixos-config — evaluated and dropped

Investigated as a possible niri+Quickshell donor: its macOS-style shell is Hyprland-bound (no QML in repo, all hosts run Hyprland HM config, niri module is a stub faking `XDG_CURRENT_DESKTOP=Hyprland`). Nothing to merge; recorded here so it is not revisited.
