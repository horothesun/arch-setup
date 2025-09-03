#!/bin/bash

# uncomment to view debugging information
set -xeuo pipefail

# config options
TARGET="/dev/sda"
HOSTNAME="archlinux01"
USER_NAME="user"
LOCALE="en_GB.UTF-8"
KEYMAP="uk"
TIMEZONE="Europe/London"
EFI_PARTITION_SIZE="600M"
LINUX_PARTITION_LABEL="LINUX"
MAKE_PARALLEL_JOBS_LOGICAL_CORES_PERCENTAGE="0.95"

# check if we're root
if [[ "$UID" -ne 0 ]]; then
    echo "This script needs to be run as root!" >&2
    exit 3
fi

read -s -p "Provide the disk encryption password: " CRYPT_PASSWORD
echo

read -s -p "Provide the \"${USER_NAME}\" user's password: " USER_PASSWORD
echo

ROOT_MNT="/mnt"

# packages to pacstrap
PACSTRAP_PACKAGES=(
    amd-ucode
    base
    base-devel
    btrfs-progs
    cryptsetup
    dosfstools
    efibootmgr
    linux
    linux-firmware
    linux-lts
    networkmanager
    sbctl
    sudo
    util-linux
)

PACMAN_PACKAGES_ALL=(
    alacritty
    alsa-utils
    amdgpu_top
    asciiquarium
    bash-completion
    bash-language-server
    bat
    bc
    bluez
    bluez-utils
    bluez-deprecated-tools
    pavucontrol
    btop
    cmatrix
    cliphist
    dive
    fastfetch
    fzf
    git
    github-cli
    git-filter-repo
    htop
    jq
    kdeconnect
    keyd
    man-db
    man-pages
    mtools
    ncdu
    neovim
    noto-fonts-emoji
    openssh
    pavucontrol
    plocate
    pipewire
    pipewire-jack
    pipewire-pulse
    python-cookiecutter
    reflector
    sbt
    snapper
    snap-pac
    speedtest-cli
    starship
    stow
    telegram-desktop
    tldr
    translate-shell
    tree
    ttf-jetbrains-mono-nerd
    ttf-firacode-nerd
    ufw
    yq
    wget
    wl-clipboard
    wtype
    zsh
)
PACMAN_PACKAGES=(
    alsa-utils
    bash-completion
    bluez
    bluez-utils
    bluez-deprecated-tools
    btop
    fastfetch
    git
    htop
    jq
    keyd
    man-db
    man-pages
    mtools
    ncdu
    neovim
    noto-fonts-emoji
    openssh
    plocate
    reflector
    snapper
    snap-pac
    stow
    tree
    ttf-jetbrains-mono-nerd
    ttf-firacode-nerd
    ufw
    wget
    zsh
)

### Desktop packages
HYPRLAND_PACKAGES_ALL=(
    dolphin
    hypridle
    hyprland
    hyprlock
    hyprshot
    hyprpolkitagent
    kitty
    kwalletmanager
    kwallet-pam
    polkit-kde-agent
    qt5-wayland
    qt6-wayland
    rofi-emoji
    rofi-wayland
    sddm
    swaync
    uwsm
    waybar
    xdg-desktop-portal-hyprland
)
HYPRLAND_PACKAGES=(
    dolphin
    hypridle
    hyprland
    hyprpolkitagent
    kitty
    kwalletmanager
    kwallet-pam
    polkit-kde-agent
    qt5-wayland
    qt6-wayland
    rofi-wayland
    sddm
    swaync
    uwsm
    xdg-desktop-portal-hyprland
)
PLASMA_PACKAGES=(
    plasma
    sddm
    kitty
    nm-connection-editor
    mousepad
)
XFCE_PACKAGES=(
    xfce4
    xfce4-terminal
    xfce4-goodies
    sddm
    nm-connection-editor
    mousepad
)

AUR_PACKAGES_ALL=(
    brave-bin
    btrfs-assistant
    informant
    jetbrains-toolbox
    oh-my-zsh-git
    scala-cli
    sddm-astronaut-theme
    terraform-ls
)
AUR_PACKAGES=(
    brave-bin
    btrfs-assistant
    oh-my-zsh-git
    sddm-astronaut-theme
)

# set locale, timezone, NTP
loadkeys "${KEYMAP}"
timedatectl set-timezone "${TIMEZONE}"
timedatectl set-ntp true

# Creating partitions...
sgdisk -Z "${TARGET}"
# https://wiki.archlinux.org/title/GPT_fdisk#Partition_type
# ef00: EFI System
# 8309: Linux LUKS
sgdisk \
    -n1:0:"+${EFI_PARTITION_SIZE}" -t1:ef00 -c1:EFI \
    -N2                            -t2:8309 -c2:"${LINUX_PARTITION_LABEL}" \
    "${TARGET}"
sleep 2
echo
# Reload partition table...
partprobe -s "${TARGET}"
sleep 2
echo

# Encrypting root partition...
echo -n "${CRYPT_PASSWORD}" | cryptsetup luksFormat --type luks2 "/dev/disk/by-partlabel/${LINUX_PARTITION_LABEL}" -
echo -n "${CRYPT_PASSWORD}" | cryptsetup luksOpen "/dev/disk/by-partlabel/${LINUX_PARTITION_LABEL}" root -
echo

# Making the File Systems...
# Create file systems
mkfs.vfat -F32 -n EFI "/dev/disk/by-partlabel/EFI"
mkfs.btrfs -f -L "${LINUX_PARTITION_LABEL}" /dev/mapper/root
echo
# Mounting the encrypted partition...
mount "/dev/mapper/root" "${ROOT_MNT}"
echo
# Create BTRFS subvolumes...
cd "${ROOT_MNT}"
btrfs subvolume create "@"
btrfs subvolume create "@home"
btrfs subvolume create "@opt"
btrfs subvolume create "@srv"
btrfs subvolume create "@cache"
btrfs subvolume create "@images"
btrfs subvolume create "@log"
btrfs subvolume create "@spool"
btrfs subvolume create "@tmp"
cd -
umount "${ROOT_MNT}"
echo
# Mounting BTRFS subvolumes...
function mountBtrfsSubvolume() {
    mkdir -p "$2"
    mount --options "noatime,ssd,compress=zstd:1,space_cache=v2,discard=async,subvol=$1" \
        "/dev/mapper/root" \
        "$2"
}
mountBtrfsSubvolume "@"       "${ROOT_MNT}/"
mountBtrfsSubvolume "@home"   "${ROOT_MNT}/home"
mountBtrfsSubvolume "@opt"    "${ROOT_MNT}/opt"
mountBtrfsSubvolume "@srv"    "${ROOT_MNT}/srv"
mountBtrfsSubvolume "@cache"  "${ROOT_MNT}/var/cache"
mountBtrfsSubvolume "@images" "${ROOT_MNT}/var/lib/libvirt/images"
mountBtrfsSubvolume "@log"    "${ROOT_MNT}/var/log"
mountBtrfsSubvolume "@spool"  "${ROOT_MNT}/var/spool"
mountBtrfsSubvolume "@tmp"    "${ROOT_MNT}/var/tmp"
echo
# Mounting EFI partition...
mkdir -p "${ROOT_MNT}/efi"
mount -t vfat "/dev/disk/by-partlabel/EFI" "${ROOT_MNT}/efi"
echo

# inspect filesystem changes
lsblk
echo
blkid
echo

# update pacman mirrors and then pacstrap base install
# Pacstrapping...
reflector --country GB --age 24 --protocol http,https --sort rate --save "/etc/pacman.d/mirrorlist"
pacstrap -K "${ROOT_MNT}" "${PACSTRAP_PACKAGES[@]}"
echo

# Generate filesystem table...
genfstab -U -p "${ROOT_MNT}" >> "${ROOT_MNT}/etc/fstab"
cat "${ROOT_MNT}/etc/fstab"
echo

# Setting up environment...
# set up locale/env: add our locale to locale.gen
sed -i -e "/^#"${LOCALE}"/s/^#//" "${ROOT_MNT}/etc/locale.gen"
# remove any existing config files that may have been pacstrapped, systemd-firstboot will then regenerate them
rm "${ROOT_MNT}"/etc/{machine-id,localtime,hostname,shadow,locale.conf} ||
systemd-firstboot \
    --root "${ROOT_MNT}" \
    --keymap="${KEYMAP}" \
    --locale="${LOCALE}" \
    --locale-messages="${LOCALE}" \
    --timezone="${TIMEZONE}" \
    --hostname="${HOSTNAME}" \
    --setup-machine-id \
    --welcome=false
arch-chroot "${ROOT_MNT}" locale-gen
echo

# Configuring for first boot...
# install the 'whois' package to get the mkpasswd tool
pacman -Sy whois --noconfirm --quiet
USER_PASSWORD_HASH=$( mkpasswd --method=sha-512 "${USER_PASSWORD}" )
# add the local user
arch-chroot "${ROOT_MNT}" useradd -G wheel -m -p "${USER_PASSWORD_HASH}" "${USER_NAME}"
# uncomment the wheel group in the sudoers file
sed -i -e '/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^# //' "${ROOT_MNT}/etc/sudoers"
# create /etc/kernel/cmdline (if the file doesn't exist, mkinitcpio will complain)
export LINUX_LUKS_UUID=$( blkid --match-tag UUID --output value "/dev/disk/by-partlabel/${LINUX_PARTITION_LABEL}" )
# TODO: full options: rd.luks.name=${LINUX_LUKS_UUID}=root root=/dev/mapper/root rootflags=subvol=@ rd.luks.options=discard rw mem_sleep_default=deep
echo "quiet rw rd.luks.name=${LINUX_LUKS_UUID}=root root=/dev/mapper/root rootflags=subvol=@" > "${ROOT_MNT}/etc/kernel/cmdline"
echo
cat "${ROOT_MNT}/etc/kernel/cmdline"
echo
# update /etc/mkinitcpio.conf
# - add the i2c-dev module for the ddcutil (external monitor brightness/contrast control)
# - change the HOOKS in mkinitcpio.conf to use systemd hooks (udev -> systemd, keymap consolefont -> sd-vconsole sd-encrypt)
# Note: original HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck grub-btrfs-overlayfs)
sed -i \
    -e '/^MODULES=(.*/c\MODULES=(btrfs i2c-dev)' \
    -e '/^BINARIES=(.*/c\BINARIES=(/usr/bin/btrfs)' \
    -e '/^FILES=(.*/c\FILES=()' \
    -e '/^HOOKS=(.*/c\HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole sd-encrypt block filesystems fsck)' \
    "${ROOT_MNT}/etc/mkinitcpio.conf"
# change the preset files to generate a Unified Kernel Images instead of an initram disk + kernel
cat <<EOF > "${ROOT_MNT}/etc/mkinitcpio.d/linux.preset"
# mkinitcpio preset file for the 'linux' package

#ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"

PRESETS=('default' 'fallback')

#default_config="/etc/mkinitcpio.conf"
#default_image="/boot/initramfs-linux.img"
default_uki="/efi/EFI/Linux/arch-linux.efi"
#default_options="--splash=/usr/share/systemd/bootctl/splash-arch.bmp"

#fallback_config="/etc/mkinitcpio.conf"
#fallback_image="/boot/initramfs-linux-fallback.img"
fallback_uki="/efi/EFI/Linux/arch-linux-fallback.efi"
fallback_options="-S autodetect"
EOF
echo
cat <<EOF > "${ROOT_MNT}/etc/mkinitcpio.d/linux-lts.preset"
# mkinitcpio preset file for the 'linux-lts' package

#ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux-lts"

PRESETS=('default' 'fallback')

#default_config="/etc/mkinitcpio.conf"
#default_image="/boot/initramfs-linux-lts.img"
default_uki="/efi/EFI/Linux/arch-linux-lts.efi"
#default_options="--splash /usr/share/systemd/bootctl/splash-arch.bmp"

#fallback_config="/etc/mkinitcpio.conf"
#fallback_image="/boot/initramfs-linux-lts-fallback.img"
fallback_uki="/efi/EFI/Linux/arch-linux-lts-fallback.efi"
fallback_options="-S autodetect"
EOF
echo

# read the linux UKI setting and create the folder structure otherwise mkinitcpio will crash
declare $(grep default_uki "${ROOT_MNT}/etc/mkinitcpio.d/linux.preset")
declare $(grep fallback_uki "${ROOT_MNT}/etc/mkinitcpio.d/linux.preset")
declare default_uki_dirname=$(dirname "${default_uki//\"}")
arch-chroot "${ROOT_MNT}" echo "default_uki: ${default_uki}"
arch-chroot "${ROOT_MNT}" echo "fallback_uki: ${fallback_uki}"
arch-chroot "${ROOT_MNT}" echo "default_uki_dirname: ${default_uki_dirname}"
arch-chroot "${ROOT_MNT}" mkdir -p "${default_uki_dirname}"
echo

# read the linux-lts UKI setting and create the folder structure otherwise mkinitcpio will crash
declare $(grep default_uki "${ROOT_MNT}/etc/mkinitcpio.d/linux-lts.preset" | sed 's/default_uki=/default_lts_uki=/g')
declare $(grep fallback_uki "${ROOT_MNT}/etc/mkinitcpio.d/linux-lts.preset" | sed 's/fallback_uki=/fallback_lts_uki=/g')
declare default_lts_uki_dirname=$(dirname "${default_lts_uki//\"}")
arch-chroot "${ROOT_MNT}" echo "default_lts_uki: ${default_lts_uki}"
arch-chroot "${ROOT_MNT}" echo "fallback_lts_uki: ${fallback_lts_uki}"
arch-chroot "${ROOT_MNT}" echo "default_lts_uki_dirname: ${default_lts_uki_dirname}"
arch-chroot "${ROOT_MNT}" mkdir -p "${default_lts_uki_dirname}"
echo

# Customize pacman.conf...
sed -i \
    -e '/#\[multilib\]/,+1s/^#//' \
    -e '/^#Color/s/^#//' \
    -e '/^#CheckSpace/s/^#//' \
    -e '/^#ParallelDownloads.*/s/^#//' \
    -e '/^ParallelDownloads.*/c\ParallelDownloads = 10' \
    -e '/^#VerbosePkgLists/s/^#//' \
    "${ROOT_MNT}/etc/pacman.conf"
echo

# Installing base packages...
arch-chroot "${ROOT_MNT}" pacman -Sy "${PACMAN_PACKAGES[@]}" --noconfirm --quiet
echo

# Installing GUI packages...
arch-chroot "${ROOT_MNT}" pacman -Sy "${HYPRLAND_PACKAGES[@]}" --noconfirm --quiet
echo

# Enable services...
systemctl --root "${ROOT_MNT}" enable bluetooth keyd NetworkManager sddm systemd-resolved systemd-timesyncd
echo
# mask systemd-networkd as we will use NetworkManager instead
systemctl --root "${ROOT_MNT}" mask systemd-networkd
echo
# TODO: check if it's needed or we're spinning up hypridle on hyprland startup 🔥🔥🔥
arch-chroot "${ROOT_MNT}" su - "${USER_NAME}" --command "sudo systemctl --user enable hypridle.service"
echo

# Firewall configuration...
# TODO: fix 🔥🔥🔥
#arch-chroot "${ROOT_MNT}" /bin/bash -c "
#    ufw default deny incoming &&
#    ufw default allow outgoing &&
#    ufw limit SSH &&
#    ufw allow Transmission
#"
#systemctl --root "${ROOT_MNT}" enable ufw
#echo
#echo "⚠️⚠️⚠️ TODO: After rebooting, run: ufw --force enable && ufw status verbose"
#echo

# Generating UKIs and installing Boot Loader...
arch-chroot "${ROOT_MNT}" mkinitcpio --preset linux
echo
echo "UKI images in ${default_uki_dirname}"
arch-chroot "${ROOT_MNT}" ls -lah "${default_uki_dirname}"
echo
# Remove any leftover initramfs-*.img images...
arch-chroot "${ROOT_MNT}" rm /boot/initramfs-linux.img /boot/initramfs-linux-fallback.img
echo
arch-chroot "${ROOT_MNT}" mkinitcpio --preset linux-lts
echo
echo "UKI images in ${default_lts_uki_dirname}"
arch-chroot "${ROOT_MNT}" ls -lah "${default_lts_uki_dirname}"
echo
# Remove any leftover initramfs-*.img images...
arch-chroot "${ROOT_MNT}" rm /boot/initramfs-linux-lts.img /boot/initramfs-linux-lts-fallback.img
echo

# systemd-boot setup...
mkdir -p "${ROOT_MNT}/efi/loader"
cat <<EOF > "${ROOT_MNT}/efi/loader/loader.conf"
timeout 5
console-mode max
editor no
EOF
echo
arch-chroot "${ROOT_MNT}" bootctl --esp-path=/efi install
systemctl --root "${ROOT_MNT}" enable systemd-boot-update
echo
# cleaup /efi/EFI
arch-chroot "${ROOT_MNT}" rm -fr /efi/EFI/systemd
arch-chroot "${ROOT_MNT}" ls -lahR /efi/EFI
echo
# check the boot entry for Arch Linux has been created and its index is the first in the boot order
arch-chroot "${ROOT_MNT}" efibootmgr
echo

# Secure Boot...
arch-chroot "${ROOT_MNT}" sbctl status
if [[ "$(efivar --print-decimal --name 8be4df61-93ca-11d2-aa0d-00e098032b8c-SetupMode)" -eq 1 ]]; then
    echo "Setting up Secure Boot..."
    arch-chroot "${ROOT_MNT}" sbctl create-keys
    arch-chroot "${ROOT_MNT}" sbctl enroll-keys --microsoft
    arch-chroot "${ROOT_MNT}" sbctl sign --save --output "/usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed" "/usr/lib/systemd/boot/efi/systemd-bootx64.efi"
    arch-chroot "${ROOT_MNT}" sbctl sign --save "/efi/EFI/BOOT/BOOTX64.EFI"
    arch-chroot "${ROOT_MNT}" sbctl sign --save "${default_uki//\"}"
    arch-chroot "${ROOT_MNT}" sbctl sign --save "${fallback_uki//\"}"
    arch-chroot "${ROOT_MNT}" sbctl sign --save "${default_lts_uki//\"}"
    arch-chroot "${ROOT_MNT}" sbctl sign --save "${fallback_lts_uki//\"}"
else
    echo "Not in Secure Boot setup mode. Skipping..."
fi
echo

# Optimize mirror list
arch-chroot "${ROOT_MNT}" reflector --country GB --age 24 --protocol http,https --sort rate --save "/etc/pacman.d/mirrorlist"
echo

# Enable parallel compilation...
LOGICAL_CORES=$( grep '^processor' /proc/cpuinfo | sort -u | wc -l )
MAKE_PARALLEL_JOBS_NUMBER=$( echo "(${MAKE_PARALLEL_JOBS_LOGICAL_CORES_PERCENTAGE} * ${LOGICAL_CORES}) / 1" | bc )
sed -i -e '/^#MAKEFLAGS=.*/c\MAKEFLAGS="-j'"${MAKE_PARALLEL_JOBS_NUMBER}"'"' "${ROOT_MNT}/etc/makepkg.conf"
cat "${ROOT_MNT}/etc/makepkg.conf" | grep "MAKEFLAGS="
echo

# YAY install...
arch-chroot "${ROOT_MNT}" su - "${USER_NAME}" --command "git clone https://aur.archlinux.org/yay-git.git ; cd yay-git ; makepkg --syncdeps --install --noconfirm ; cd .. ; rm -rf yay-git"
echo

# YAY update and setup packages...
arch-chroot "${ROOT_MNT}" su - "${USER_NAME}" --command "yay -Syu --noconfirm --norebuild --answerdiff=None --answeredit=None"
export AUR_PACKAGES_SAME_LINE="${AUR_PACKAGES[@]}"
arch-chroot "${ROOT_MNT}" su - "${USER_NAME}" --command "yay -S --noconfirm --norebuild --answerdiff=None --answeredit=None ${AUR_PACKAGES_SAME_LINE}"
echo


## ZSH set as default...
arch-chroot "${ROOT_MNT}" chsh --list-shells
arch-chroot "${ROOT_MNT}" chsh --shell=/usr/bin/zsh "${USER_NAME}"
echo

# snapper setup...
## create snapper config for / (`--no-dbus` used because in arch-chroot environment)
arch-chroot "${ROOT_MNT}" snapper --no-dbus --config root create-config /
arch-chroot "${ROOT_MNT}" snapper --no-dbus list-configs
echo
## allow the user to manage root snapshots
arch-chroot "${ROOT_MNT}" snapper --no-dbus --config root set-config ALLOW_USERS="${USER_NAME}" SYNC_ACL=yes
arch-chroot "${ROOT_MNT}" ls -lahd /.snapshots/

## APPEND '.snapshots' to /etc/updatedb.conf in the 'PRUNENAMES' space-separated list,
## to avoid slowing down the system when there're lots of snapshots
sed -i -e '/^PRUNENAMES.*/c\PRUNENAMES = ".git .hg .svn .snapshots"' "${ROOT_MNT}/etc/updatedb.conf"
cat "${ROOT_MNT}/etc/updatedb.conf"
echo

# disable automatic timeline snapshots (temporarily, to avoid snapshots to be created while setting up snapper)
systemctl --root "${ROOT_MNT}" disable snapper-timeline.timer snapper-cleanup.timer

# we shouldn't have any snapshots yet
arch-chroot "${ROOT_MNT}" snapper --no-dbus list

# TODO: setup bootloader snapshots auto-updater 🔥🔥🔥
# ...

# create first snapshot
arch-chroot "${ROOT_MNT}" snapper --no-dbus --config root create --description "*** BEGINNING OF TIME ***"
arch-chroot "${ROOT_MNT}" snapper --no-dbus list

# enable automatic timeline snapshots (JUST FOR root CONFIG)
systemctl --root "${ROOT_MNT}" enable snapper-timeline.timer snapper-cleanup.timer


# SDDM theme...
cat <<EOF > "${ROOT_MNT}/etc/sddm.conf"
[Theme]
Current=sddm-astronaut-theme
EOF
mkdir -p "${ROOT_MNT}/etc/sddm.conf.d"
cat <<EOF > "${ROOT_MNT}/etc/sddm.conf.d/virtualkbd.conf"
[General]
InputMethod=qtvirtualkeyboard
EOF
cat "${ROOT_MNT}/etc/sddm.conf.d/virtualkbd.conf"
echo
sed -i "s/^ConfigFile=.*/ConfigFile=Themes\/purple_leaves.conf/g" "${ROOT_MNT}/usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop"
sed -i \
    -e '/^ScreenWidth=.*/c\ScreenWidth="2560"' \
    -e '/^ScreenHeight=.*/c\ScreenHeight="1440"' \
    -e '/^DateFormat=.*/c\DateFormat="ddd, dd MMMM"' \
    -e '/^TranslateVirtualKeyboardButtonOn=.*/c\TranslateVirtualKeyboardButtonOn=" "' \
    -e '/^TranslateVirtualKeyboardButtonOff=.*/c\TranslateVirtualKeyboardButtonOff=" "' \
    "${ROOT_MNT}/usr/share/sddm/themes/sddm-astronaut-theme/Themes/purple_leaves.conf"
echo

# lock the root account
arch-chroot "${ROOT_MNT}" usermod --lock root
echo

# ZRAM / Swap setup
# TODO: consider for hibernation (suspend-to-disk)...

#-----------------------------------
#- Install complete. Please reboot -
#-----------------------------------
sleep 10
sync
echo
# reboot
