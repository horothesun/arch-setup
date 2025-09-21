# Arch Linux auto-install script

## Target machine

- Desktop PC (no power-management tools)
- AMD or Intel CPU with iGPU
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

## Let's go!

- (optional) enable UEFI Secure Boot's "Setup mode" and reset keys
- boot into Arch live USB
- increase font size: `setfont ter-120f`
- connect to Wi-Fi

```bash
iwctl
iwctl device list
iwctl station <DEVICE_NAME> get-networks
iwctl station list
iwctl station <DEVICE_NAME> connect <NETWORK_NAME>
<NETWORK_PASSWORD>
iwctl station list

# test connection
ping -c 5 archlinux.org
```

- enable SSH daemon to continue Arch setup from another PC via SSH

```bash
systemctl status sshd
systemctl start sshd

# create a password for root user (on the live USB install)
passwd
New password: 123
Retype new password: 123

# get IP address
ip a
```

- (from another PC) SSH into live USB install

```bash
ssh root@<LIVE_USB_IP_ADDRESS>
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
root@<LIVE_USB_IP_ADDRESS>'s password: 123
```

- copy auto-install script to the live USB install

```bash
scp ~/path/to/arch_auto_install.sh "root@<LIVE_USB_INSTALL_IP>:/root/arch_auto_install.sh"
```

- edit script's config parameters (e.g. `TARGET`, `HOST_NAME` and `USER_NAME`) and run it with

```bash
chmod +x arch_auto_install.sh
./arch_auto_install.sh
```

- reboot
- (from the other PC) reset ssh key

```bash
ssh-keygen -R <LIVE_USB_INSTALL_IP>
```

- follow [`first_boot_setup.md`](first_boot_setup.md)
