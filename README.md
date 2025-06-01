# `archinstall`-based setup

## TODOs

### Secure boot

- [Unified Extensible Firmware Interface/Secure Boot](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot)
- [Firmware known quirk](https://github.com/Foxboron/sbctl/wiki/FQ0001)
- [dev.to - Enabling Secure Boot with Linux and Windows Dual-Boot Setup](https://dev.to/berk/complete-guide-enabling-secure-boot-with-linux-and-windows-dual-boot-setup-24o8)
- [Arch Install with Secure Boot, btrfs, TPM2 LUKS encryption, Unified Kernel Images](https://walian.co.uk/arch-install-with-secure-boot-btrfs-tpm2-luks-encryption-unified-kernel-images.html)

### Arch Linux manual install

- [2025 Arch Linux Install with COSMIC | Full Step-by-Step Guide - BTRFS, Encrypt, Zram, Timeshift](https://www.youtube.com/watch?v=fFxWuYui2LI)
- [journalctl Basics: How to Easily Check Your Linux Logs](https://www.youtube.com/watch?v=0dG3vUYt7Uk)
- [`zsh` install](https://wiki.archlinux.org/title/Zsh)
- Hyprland
  - recognise `~/bin` folder
  - shutdown on keyboard shortcut
  - swap Windows key with `Alt`
- Brave browser + KWallet: fix cookies wiping on restart

## Video references

- [Arch Linux with Snapshots: Install Arch Linux (2025) - Part 1/3](https://www.youtube.com/watch?v=FiK1cGbyaxs)
- [Arch Linux Installation Guide (including BTRFS, QTile, ZRAM, disk encryption, timeshift)](https://www.youtube.com/watch?v=Qgg5oNDylG8)

## Base install

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

## Disk partitioning

- Get disk name (check `TYPE` being `disk`) by running `lsblk`
- Partition the disk
  1. EFI system partition: `1GiB`, `fat32`, mount point `/efi`, **mark as bootable**
  2. Linux system partition: remaining space, `btrfs`, mount point `/`, **mark as compressed**

### Subvolumes

| Name | Mount point | Notes |
| :--- | :---------- | :---- |
| `@` | `/` | |
| `@home` | `/home` | |
| `@opt` | `/opt` | apps installed by 3rd party |
| `@srv` | `/srv` | locally hosted servers |
| `@cache` | `/var/cache` | persistent system cached data |
| `@images` | `/var/lib/libvirt/images` | VM images managed by `libvirt` |
| `@log` | `/var/log` | system logs |
| `@spool` | `/var/spool` | data awaiting later processing, e.g. print queue |
| `@tmp` | `/var/tmp` | large temporary files |

## archinstall

NOTE: `archinstall` code fix

> IMPORTANT: use tabs, not spaces!

```diff
diff --git a/archinstall/lib/models/device_model.py b/archinstall/lib/models/device_model.py
index 13f12b3f..077d4bc5 100644
--- a/archinstall/lib/models/device_model.py
+++ b/archinstall/lib/models/device_model.py
@@ -938,9 +938,7 @@ class PartitionModification:
                return PartitionFlag.ESP in self.flags

        def is_boot(self) -> bool:
-               if self.mountpoint is not None:
-                       return self.mountpoint == Path("/boot")
-               return False
+               return PartitionFlag.BOOT in self.flags

        def is_root(self) -> bool:
                if self.mountpoint is not None:
```

---

If you already have `archinstall` config files available via public repo, you can load them with

```bash
archinstall --config-url="https://raw.githubusercontent.com/horothesun/archinstall-config/refs/heads/master/user_configuration.json"
```

then continue from [here](#chroot-post-install), otherwise

- Check the CPU supports LUKS disk encryption with `grep -o aes /proc/cpuinfo | uniq` (`aes` as result means yes)
- Additional packages (AMD specific): `amd-ucode bash-completion git man-db man-pages plocate neovim alacritty firefox`
- Additional repositories: `multilib` only
- Save config files to `/root/user_configuration.json`
- Copy config files from live USB install to local PC via `scp` (on the other PC run)
- From the other PC, push config files to public repo

```bash
cd "${HOME}/src/archlinux-config"
scp "root@<LIVE_USB_IP_ADDRESS>:/root/user_configuration.json" .
```

### `chroot` post-install

Disable Copy-on-Write for `virtlib` images folder with

```bash
lsattr -d /var/lib/libvirt/images/
chattr -VR +C /var/lib/libvirt/images/
```

Move `grub` from the `/efi` partition to `/boot` (part of the `/` partition) with

```bash
ls -lah /efi
ls -lah /efi/grub

# remove grub from /efi
rm -rf /efi/grub

# check the arch boot-loader folder is missing from /efi/EFI
ls -lah /efi/EFI

# create grub
grub-install --target=x86_64-efi --efi-directory=/efi --boot-directory=/boot --bootloader-id=arch

# check the arch boot-loader folder is now present in /efi/EFI
ls -lah /efi/EFI

# check the grubx64.efi boot-loader's been created
ls -lah /efi/EFI/arch

# check the grub/ folder is now present in /boot
ls -lah /boot

# check /boot/grub contains fonts/, grub.cfg, grubenv, locale/, themes/, x86_64-efi/
ls -lah /boot/grub

# if /boot/grub/grub.cfg is missing, create it and check again
grub-mkconfig -o /boot/grub/grub.cfg
ls -lah /boot/grub

# check the boot entry for Arch Linux has been created and its index is the first in the boot order
efibootmgr

# if the boot entry for Arch Linux has not been created, or it's in the wrong order, follow the instructions here:
# https://www.youtube.com/watch?v=FiK1cGbyaxs&t=1942

# complete the post-installation
exit

# check the installation completed without any errors and reboot
reboot

# add your user to the sudoers
su
export EDITOR=vim
visudo
# add the following line (after the one for the root user)
# <USER_NAME> ALL=(ALL:ALL) ALL

# [WIP] Wi-Fi setup
lspci -vnn | less
# search for "Wi-Fi"
lspci -vnn -d 17cb:

nmcli

sudo dmesg | grep ath12k

# TODO: ...
```

## Snapper setup

```bash
# check current partitions and mount points
lsblk

# list BTRFS subvolumes
sudo btrfs subvolume list /

sudo btrfs filesystem show /

# set / BTRFS system label to "ARCH"
sudo btrfs filesystem label / ARCH

sudo btrfs filesystem show /

# check space allocation and usage (breakdown here: https://www.youtube.com/watch?v=rl-VasRoUe4&t=339)
sudo btrfs filesystem usage /

# update the system
sudo pacman -Syu

sudo reboot

# ---
# if you'd like to snapshot /home, follow this guide to create subvolumes to exclude snapshotting
# folders like .ssh and browser data: https://www.youtube.com/watch?v=rl-VasRoUe4&t=718
# ---

# install YAY
git clone https://aur.archlinux.org/yay-git.git
cd yay-git
makepkg -si
cd ..
rm -rf yay-git

# update the packages
yay -Syu

# install Snapper
sudo pacman -S snapper snap-pac grub-btrfs inotify-tools

# GUI for snapshot management
yay -S btrfs-assistant

# create snapper config for /
sudo snapper -c root create-config /

sudo snapper list-configs

# allow current user to manage root snapshots
sudo snapper -c root set-config ALLOW_USERS="$USER" SYNC_ACL=yes

ls -d /.snapshots/

# APPEND '.snapshots' to /etc/updatedb.conf in the 'PRUNENAMES' space-separated list,
# to avoid slowing down the system when there're lots of snapshots
sudo vim /etc/updatedb.conf

# disable automatic timeline snapshots (temporarily, to avoid snapshots to be created while setting up snapper)
sudo systemctl status snapper-timeline.timer snapper-cleanup.timer
sudo systemctl disable --now snapper-timeline.timer snapper-cleanup.timer
sudo systemctl status snapper-timeline.timer snapper-cleanup.timer

# we shouldn't have any snapshots yet
snapper list

# enable OverlayFS to enable booting from grub into a read-only snapshot, as a live USB in a non-persistent state
# (APPEND 'grub-btrfs-overlayfs' to the 'HOOKS' space-separated list)
sudo vim /etc/mkinitcpio.conf

# regenerate initramfs
sudo mkinitcpio -P

# enable the grub-btrfsd service to auto-update grub when new snapshots are created/deleted
sudo systemctl enable --now grub-btrfsd.service
sudo systemctl status grub-btrfsd.service

# test snapper on a pacman package install
#
snapper list
sudo pacman -S banner
banner Hello
snapper list
snapper status 1..2
sudo snapper undochange 1..2
# banner should not be present now
banner Hello
sudo snapper undochange 2..1
# banner should work again now
banner Hello
sudo pacman -Rs banner
snapper list
```

### Create pre and post snapshots

```bash
# manually create a 'pre' snapshot (e.g. before experimenting with AUR packages)
snapper -c root create -t pre -c number -d "pre AUR package"
# ... install pacman and AUR packages, test the programs ...
# manually create a 'post' snapshot
snapper list
snapper -c root create -t post --pre-number <PRE_SNAPSHOT_NUMBER> -c number -d "post AUR package"
snapper list
```

### DISASTER RECOVERY: rollback from `grub`

```bash
# check /boot, /etc and /usr size and content
sudo du -sch /boot /etc /usr
ls -lah /boot

# ⚠️ DESTRUCTIVE OPERATION ⚠️ REMOVE ESSENTIAL FOLDERS!!!
sudo rm -rvf /boot/{vmlinuz,initramfs}* /etc /usr
sudo reboot

# system fails to boot!
# now boot from the latest snapshot in the "Arch Linux snapshots" grub menu

# check /boot for kernel and initramfs presence
ls -lah /boot

# launch btrfs-assistant
QT_QPA_PLATFORM=wayland btrfs-assistant-launcher
```

In `btrfs-assistant` GUI go to `Snapper` -> `Browse/Restore` -> select latest snapshot and `Restore` -> `Yes` -> `OK`,
then `reboot`.

If `grub`'s "Arch Linux snapshots" entry is not visible (due to the rollback), we'll fix it later.

After rebooting check the system again

```bash
sudo du -sch /boot /etc /usr
ls -lah /boot
```

Now fix the `grub` menu system to sync again snapshots with it

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Final setup

```bash
snapper list

# if snapshots for /home are enabled, do the following first
# sudo snapper -c home set-config TIMELINE_CREATE=no

# enable automatic timeline snapshots (JUST FOR root CONFIG)
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
# check timeline and cleanup services status
sudo systemctl status snapper-timeline.timer snapper-cleanup.timer

# create our first root snapshot
snapper -c root create --description "*** BEGINNING OF TIME ***"

# wait some time and check for the new timeline snapshot to be created
snapper list
```

## Grub repair

E.g.: after a BIOS update.

Boot with a live USB, then

```bash
# show drives and partitions
lsblk

# mount /
mount -o noatime,ssd,compress=zstd,space_cache=v2,discard=async,subvol=@ /dev/nvme0n1p2 /mnt

# mount /efi
mount /dev/nvme0n1p1 /mnt/efi

# start a shell into the system
arch-chroot /mnt

grub-install --target=x86_64-efi --efi-directory=/efi --boot-directory=/boot --bootloader-id=arch

# exit from chroot
exit

reboot
```

Now fix the BIOS boot order.

## git

```bash
eval "$(ssh-agent)"
ssh-add ~/.ssh/horothesun
```

Add `eval "$(ssh-agent)" > /dev/null` to `~/.bashrc`.

### Passphrase from script

```bash
touch "$HOME/.ssh/askpass.sh"
chmod u+x "$HOME/.ssh/askpass.sh"
```

Paste the following content in the newly created `$HOME/.ssh/askpass.sh`

```bash
#!/bin/sh

# pass "beast SSH key"
echo "<PUT_YOUR_SSH_KEY_HERE>"
```

Add the SSH key by running (encoded in `bash` config)

```bash
SSH_ASKPASS_REQUIRE="force" SSH_ASKPASS="${HOME}/.ssh/askpass.sh" ssh-add "${HOME}/.ssh/horothesun" &> /dev/null
```

### Set default editor

```bash
git config --global core.editor "nvim"
```

## Bluetooth

```bash
systemctl status bluetooth

# pair->connect->trust devices with bluetoothctl
bluetoothctl scan on
bluetoothctl devices
bluetoothctl pair <MAC-ADDRESS>
bluetoothctl connect <MAC-ADDRESS>
bluetoothctl trust <MAC-ADDRESS>
bluetoothctl devices Connected
bluetoothctl scan off
```

Control your Bluetooth audio devices with the `pavucontrol` GUI app.

### Apple Keyboard

Swap `\``/`~` with `§`/`±` keys using the `keyd` remapping daemon.

Here's the `/etc/keyd/default.conf` (`sudo keyd reload` after updating the config file)

```
[ids]

# Apple Magic Keyboard (acquire this by running `sudo keyd monitor`)
004c:0267:9cc234d0

[main]

# swap ` and §
` = 102nd
102nd = `
```

Check for config loading errors by running `sudo journalctl -eu keyd`.

## Apps

```bash
yay -S scala-cli
sudo pacman -S sbt
yay -S terraform-ls
# yay -S aws-cli-v2 # FAILED setup
```

### Brave

Install with

```bash
yay -S brave-bin
```

launch it, set `brave://flags/#ozone-platform-hint` to "Wayland" (to fix fractional scaling font issues) and restart.

Set `brave://flags/#scrollable-tabstrip` to "Enabled" to actually disable the feature.

### IntelliJ Idea IDE

Install with

```bash
yay -S intellij-idea-community-edition-bin
```

launch it (create its dot-files), close it, then enable Wayland ([blog](https://blog.jetbrains.com/platform/2024/07/wayland-support-preview-in-2024-2/))
with

```bash
echo "-Dawt.toolkit.name=WLToolkit" >> "${HOME}/.config/JetBrains/IdeaIC2025.1/idea64.vmoptions"
```
