# `archinstall`-based setup

Video refs:

- [Arch Linux with Snapshots: Install Arch Linux (2025) - Part 1/3](https://www.youtube.com/watch?v=FiK1cGbyaxs)
- [Arch Linux Installation Guide (including BTRFS, QTile, ZRAM, disk encryption, timeshift)](https://www.youtube.com/watch?v=Qgg5oNDylG8)

## Base install

- boot into Arch live USB
- increase font size: `setfont ter-120f`
- connect to Wi-Fi

```bash
iwctl
device list
station <DEVICE_NAME> get-networks
station list
station <DEVICE_NAME> connect <NETWORK_NAME>
<NETWORK_PASSWORD>
station list
exit

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
ip addr show
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

If you already have `archinstall` config files available via public repo, you can load them with

```bash
archinstall --config="https://raw.githubusercontent.com/horothesun/archinstall-config/refs/heads/master/user_configuration.json"
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
chsattr -VR +C /var/lib/libvirt/images/
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

# check the grub folder is now present in /boot
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
```

## Snapper setup

```bash
# check current partitions and mount points
lsblk

# list BTRFS subvolumes
sudo btrfs subvolumes list /

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
sudo vi /etc/updatedb.conf

# disable automatic timeline snapshots (temporarily, to avoid snapshots to be created while setting up snapper)
sudo systemctl status snapper-timeline.timer snapper-cleanup.timer
sudo systemctl disable --now snapper-timeline.timer snapper-cleanup.timer
sudo systemctl status snapper-timeline.timer snapper-cleanup.timer

# we shouldn't have any snapshots yet
snapper ls

# enable OverlayFS to enable booting from grub into a read-only snapshot, as a live USB in a non-persistent state
# (APPEND 'grub-btrfs-overlayfs' to the 'HOOKS' space-separated list)
sudo vi /etc/mkinitcpio.conf

# regenerate initramfs
sudo mkinitcpio -P

# enable the grub-btrfsd service to auto-update grub when new snapshots are created/deleted
sudo systemctl enable --now grub-btrfsd.service
sudo systemctl status grub-btrfsd.service

# test snapper on a pacman package install
#
snapper ls
sudo pacman -S banner
banner Hello
snapper ls
snapper status 1..2
sudo snapper undochange 1..2
# banner should not be present now
banner Hello
sudo snapper undochange 2..1
# banner should work again now
banner Hello
pacman -Rs banner
snapper ls

# manually create a 'pre' snapshot (e.g. before experimenting with AUR packages)
snapper -c root create -t pre -c number -d "pre AUR package"
# ... install pacman and AUR packages, test the programs ...
# manually create a 'post' snapshot
snapper ls
snapper -c root create -t post --pre-number <PRE_SNAPSHOT_NUMBER> -c number -d "post AUR package"
snapper ls
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
```

Open `btrfs-assistant` GUI -> `Snapper` -> `Browse/Restore` -> select latest snapshot and `Restore` -> `Yes` -> `OK`,
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
snapper ls

# if snapshots for /home are enabled, do the following first
# sudo snapper -c home set-config TIMELINE_CREATE=no

# enable automatic timeline snapshots (JUST FOR root CONFIG)
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer

# wait some time and check for the new timeline snapshot to be created
snapper ls
```
