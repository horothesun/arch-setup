# Arch Linux setup

## Target machine

- Desktop PC
- AMD CPU with iGPU
- Lots of RAM
- Full Linux-dedicated disk

## Features

- EFI and Linux partitions (no swap)
- LUKS2 disk encryption
- Secure Boot (optional, if "Setup mode" is on)
- BTRFS file system with Snapper `root` snapshots (and [snapper-rollback](https://aur.archlinux.org/packages/snapper-rollback)<sup>AUR</sup>)
- `linux` and `linux-lts` kernels
- Unified Kernel Images (via `mkinitcpio`)
- Systemd-boot bootloader
  - "recovery" boot: the `linux-lts` fallback entry is configured for terminal login to perform BTRFS snapshot rollbacks
- `make` configured for parallel compilation (using $⌋95%⌊$ of available logical cores)
- `yay` AUR helper
- SDDM login manager with [sddm-astronaut-theme](https://aur.archlinux.org/packages/sddm-astronaut-theme)<sup>AUR</sup> theme
- Hyprland (Wayland) window manager
- ZSH shell
