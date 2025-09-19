# Arch Linux auto-install script

## Target machine

- Desktop PC
- AMD CPU with iGPU
- Lots of RAM
- SSD fully dedicated to Linux

## Features

- Fully testable on virtual machines
- EFI and Linux partitions (no swap, so no hibernate)
- LUKS2 disk encryption
- Secure Boot (optional, if "Setup mode" is on)
- BTRFS file system
  - [snapper](https://archlinux.org/packages/extra/x86_64/snapper) `/` snapshots,
  - [snap-pac](https://archlinux.org/packages/extra/any/snap-pac) pacman hooks and
  - [snapper-rollback](https://aur.archlinux.org/packages/snapper-rollback)<sup>AUR</sup>
- [linux](https://archlinux.org/packages/core/x86_64/linux) and [linux-lts](https://archlinux.org/packages/core/x86_64/linux-lts) kernels
- Unified Kernel Images (via `mkinitcpio`)
- Systemd-boot bootloader
  - "recovery" boot: the [linux-lts](https://archlinux.org/packages/core/x86_64/linux-lts) fallback entry is configured for terminal login to perform BTRFS snapshot rollbacks
- `make` configured for parallel compilation (using 95% of available logical cores)
- [yay](https://aur.archlinux.org/packages/yay)<sup>AUR</sup> AUR helper
- [zsh](https://archlinux.org/packages/extra/x86_64/zsh) shell with [oh-my-zsh-git](https://aur.archlinux.org/packages/oh-my-zsh-git)<sup>AUR</sup> configuration framework
- SDDM login manager with [sddm-astronaut-theme](https://aur.archlinux.org/packages/sddm-astronaut-theme)<sup>AUR</sup> theme
- Hyprland (Wayland) window manager
