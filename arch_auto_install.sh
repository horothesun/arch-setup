#!/bin/bash

# uncomment to view debugging information
set -xeuo pipefail

# config options
TARGET="/dev/sda"
HOST_NAME="archlinux01"
USER_NAME="user"
LOCALE="en_GB.UTF-8"
KEYMAP="uk"
TIMEZONE="Europe/London"
EFI_PARTITION_SIZE="800M"
MAKE_PARALLEL_JOBS_LOGICAL_CORES_PERCENTAGE="0.95"
LINUX_PARTITION_LABEL="LINUX"
ROOT_MNT="/mnt"

# check if we're root
if [[ "$UID" -ne 0 ]]; then
    echo "This script needs to be run as root!" >&2
    exit 3
fi
echo

# packages to pacstrap
MICROCODE_PACKAGE=$( if lscpu | grep -q "AuthenticAMD"; then echo "amd-ucode"; else echo "intel-ucode"; fi )
PACSTRAP_PACKAGES=(
    "${MICROCODE_PACKAGE}"
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

PACMAN_PACKAGES=(
    alacritty # A cross-platform, GPU-accelerated terminal emulator
    alsa-utils # Advanced Linux Sound Architecture - Utilities
    asciiquarium # An aquarium/sea animation in ASCII art
    aws-cli-v2 # Universal Command Line Interface for Amazon Web Services (version 2)
    bash-completion # Programmable completion for the bash shell
    bash-language-server
    bat # Cat clone with syntax highlighting and git integration
    bc # An arbitrary precision calculator language
    bluetui # TUI for managing bluetooth devices
    bluez # Daemons for the bluetooth protocol stack
    bluez-utils # Development and debugging utilities for the bluetooth protocol stack
    bluez-deprecated-tools # Deprecated tools that are no longer maintained
    browserpass # Native host app for Browserpass, browser extension for zx2c4's pass (password manager)
    browserpass-chromium # Chromium extension for Browserpass, browser extension for zx2c4's pass (password manager)
    btop # A monitor of system resources, bpytop ported to C++
    cmatrix # A curses-based scrolling 'Matrix'-like screen
    dive # A tool for exploring layers in a docker image
    fastfetch # A feature-rich and performance oriented neofetch like system information tool
    fd # Simple, fast and user-friendly alternative to find
    fzf # Command-line fuzzy finder
    git # the fast distributed version control system
    github-cli # The GitHub CLI
    gitu # A TUI Git client inspired by Magit
    git-filter-repo # Quickly rewrite git repository history (filter-branch replacement)
    guvcview # Simple GTK+ interface for capturing and viewing video from v4l2 devices
    htop # Interactive process viewer
    jami-qt # Free and universal communication platform which preserves the users’ privacy and freedoms
    jq # Command-line JSON processor
    kdeconnect # Adds communication between KDE and your smartphone
    keyd # A key remapping daemon for linux
    lua-language-server
    man-db # A utility for reading man pages
    man-pages # Linux man pages
    ncdu # Disk usage analyzer with an ncurses interface
    neovim # Fork of Vim aiming to improve user experience, plugins, and GUIs
    noto-fonts-emoji # Google Noto Color Emoji font
    obs-studio # Free, open source software for live streaming and recording
    onnxruntime-opt-rocm # Cross-platform, high performance scoring engine for ML models (with ROCm and AVX2 CPU optimizations)
    openssh # SSH protocol implementation for remote login, command execution and file transfer
    pass # Stores, retrieves, generates, and synchronizes passwords securely
    pavucontrol # PulseAudio Volume Control
    plocate # Alternative to locate, faster and compatible with mlocate's database
    pipewire # Low-latency audio/video router and processor
    pipewire-alsa # Low-latency audio/video router and processor - ALSA configuration
    pipewire-audio # Low-latency audio/video router and processor - Audio support
    pipewire-jack # Low-latency audio/video router and processor - JACK replacement
    pipewire-pulse # Low-latency audio/video router and processor - PulseAudio replacement
    pyright # Type checker for the Python language
    python-cookiecutter # A command-line utility that creates projects from project templates
    python-lsp-server # Fork of the python-language-server project, maintained by the Spyder IDE team and the community
    reflector # A Python 3 module and script to retrieve and filter the latest Pacman mirror list
    ruff # An extremely fast Python linter, written in Rust
    sbt # The interactive build tool
    snapper # A tool for managing BTRFS and LVM snapshots
    snap-pac # Pacman hooks that use snapper to create pre/post btrfs snapshots like openSUSE's YaST
    speedtest-cli # Command line interface for testing internet bandwidth using speedtest.net
    starship # The cross-shell prompt for astronauts
    stow # Manage installation of multiple softwares in the same directory tree
    telegram-desktop # Official Telegram Desktop client
    tldr # Command line client for tldr, a collection of simplified man pages
    translate-shell # A command-line interface and interactive shell for Google Translate
    tree # A directory listing program displaying a depth indented list of files
    ttf-firacode-nerd
    ttf-iosevkaterm-nerd
    ttf-jetbrains-mono-nerd
    ufw # Uncomplicated and easy to use CLI tool for managing a netfilter firewall
    v4l2loopback-dkms # v4l2-loopback device – module sources
    v4l2loopback-utils # v4l2-loopback device – utilities only
    v4l-utils # Userspace tools and conversion library for Video 4 Linux
    vlc # Free and open source cross-platform multimedia player and framework
    vlc-plugins-all # Free and open source cross-platform multimedia player and framework - all plugins
    yq # Command-line YAML, XML, TOML processor - jq wrapper for YAML/XML/TOML documents
    wget # Network utility to retrieve files from the web
    wireplumber # Session / policy manager implementation for PipeWire
    zsh # A very advanced and programmable command interpreter (shell) for UNIX
)

AUR_PACKAGES=(
    basedpyright # pyright fork with various improvements and pylance features
    brave-bin # Web browser that blocks ads and trackers by default (binary release)
    btrfs-assistant # An application for managing BTRFS subvolumes and Snapper snapshots
    coursier # Pure Scala Artifact Fetching
    ghcup-hs-bin # an installer for the general purpose language Haskell
    informant # An Arch Linux News reader and pacman hook
    jetbrains-toolbox # Manage all your JetBrains Projects and Tools
    obs-backgroundremoval # Background removal plugin for OBS studio
    oh-my-zsh-git # A community-driven framework for managing your zsh configuration
    scala-cli # A command-line tool to interact with the Scala language
    sddm-astronaut-theme # Modern looking sddm qt6 theme
    snapper-rollback # Script to rollback snapper snapshots as described here https://wiki.archlinux.org/index.php/Snapper#Suggested_filesystem_layout
    terraform-ls # Terraform Language Server
)

# GPU packages

AMD_GPU_PACKAGES=(
    amdgpu_top # Tool that shows AMD GPU utilization
    lib32-mesa # Open-source OpenGL drivers - 32-bit
    lib32-vulkan-icd-loader # Vulkan Installable Client Driver (ICD) Loader (32-bit)
    lib32-vulkan-radeon # Open-source Vulkan driver for AMD GPUs - 32-bit
    mesa # Open-source OpenGL drivers
    vulkan-icd-loader # Vulkan Installable Client Driver (ICD) Loader
    vulkan-radeon # Open-source Vulkan driver for AMD GPUs
    vulkan-tools # Vulkan tools and utilities
)

INTEL_GPU_PACKAGES=(
    lib32-mesa # Open-source OpenGL drivers - 32-bit
    lib32-vulkan-intel # Open-source Vulkan driver for Intel GPUs - 32-bit
    mesa # Open-source OpenGL drivers
    nvtop # GPUs process monitoring for AMD, Intel and NVIDIA
    vulkan-intel # Open-source Vulkan driver for Intel GPUs
)

# TODO: fill packages list 🔥🔥🔥
NVIDIA_GPU_PACKAGES=()

GPU_PACKAGES=( "${AMD_GPU_PACKAGES[@]}" )

# Desktop packages

# enable cosmic-greeter.service
COSMIC_PACKAGES=(
    cosmic
    sddm # QML based X11 and Wayland display manager
)

# enable gdm.service
GNOME_PACKAGES=(
    gnome
    gnome-circle
    gnome-extra
)

HYPRLAND_PACKAGES=(
    cliphist # wayland clipboard manager
    hypridle # hyprland’s idle daemon
    hyprland
    hyprlock # hyprland’s GPU-accelerated screen locking utility
    hyprpolkitagent # Simple polkit authentication agent for Hyprland, written in QT/QML
    hyprshot # Hyprland screenshot utility
    kitty # Default hyprland's terminal emulator
    kwalletmanager # Wallet management tool
    kwallet-pam # KWallet PAM integration
    polkit-kde-agent # Daemon providing a polkit authentication UI for KDE
    qt5-wayland # Provides APIs for Wayland
    qt6-wayland # Provides APIs for Wayland
    rofi # A window switcher, application launcher and dmenu replacement
    rofi-emoji # A Rofi plugin for selecting emojis
    sddm # QML based X11 and Wayland display manager
    swaync # A simple GTK based notification daemon for Sway
    thunar # Xfce File Manager
    uwsm # A standalone Wayland session manager
    waybar # Highly customizable Wayland bar for Sway and Wlroots based compositors
    wl-clipboard # Command-line copy/paste utilities for Wayland
    wtype # xdotool type for wayland
    xdg-desktop-portal-hyprland # xdg-desktop-portal backend for hyprland
)

PLASMA_PACKAGES=(
    kitty # Default hyprland's terminal emulator
    nm-connection-editor # NetworkManager GUI connection editor and widgets
    plasma
    sddm # QML based X11 and Wayland display manager
)

XFCE_PACKAGES=(
    mousepad # Simple text editor for Xfce
    nm-connection-editor # NetworkManager GUI connection editor and widgets
    sddm # QML based X11 and Wayland display manager
    xfce4
    xfce4-terminal
    xfce4-goodies
)

XMONAD_PACKAGES=(
    arandr # Provide a simple visual front end for XRandR 1.2
    brightnessctl # Lightweight brightness control tool
    copyq # Clipboard manager with searchable and editable history
    dmenu # Generic menu for X
    maim # Utility to take a screenshot using imlib2
    network-manager-applet # Applet for managing network connections
    pasystray # PulseAudio system tray (a replacement for padevchooser)
    rofi # A window switcher, application launcher and dmenu replacement
    rofi-emoji # A Rofi plugin for selecting emojis
    sddm # QML based X11 and Wayland display manager
    stalonetray # STAnd-aLONE sysTRAY. It has minimal build and run-time dependencies: the Xlib only
    sxhkd # Simple X hotkey daemon
    thunar # Xfce File Manager
    xclip # Command line interface to the X11 clipboard
    xdotool # Command-line X11 automation tool
    xmobar # Minimalistic Text Based Status Bar
    xmonad
    xmonad-contrib # Community-maintained extensions for xmonad
    xmonad-extras # Third party extensions for xmonad with wacky dependencies
    xmonad-utils # Small collection of X utilities
    xorg-xrandr # Primitive command line interface to RandR extension
    xsel # Command-line program for getting and setting the contents of the X selection
    xterm # X Terminal Emulator
)
# TODO: extend AUR_PACKAGES with this 🔥🔥🔥
XMONAD_AUR_PACKAGES=(
    auto-cpufreq # Automatic CPU speed & power optimizer
)

DESKTOP_PACKAGES=( "${HYPRLAND_PACKAGES[@]}" )

### Start!

lsblk
echo

# set locale, timezone, NTP
loadkeys "${KEYMAP}"
timedatectl set-timezone "${TIMEZONE}"
timedatectl set-ntp true

# read disk encryption password
read -s -r -p "Provide the disk encryption password: " CRYPT_PASSWORD
echo
read -s -r -p "Enter same disk encryption password again: " CRYPT_PASSWORD_2
echo
if [[ "$CRYPT_PASSWORD" = "$CRYPT_PASSWORD_2" ]]; then
    echo
else
    echo "Mismatching disk encryption password!"
    exit 123
fi

# read user's password
read -s -r -p "Provide the \"${USER_NAME}\" user's password: " USER_PASSWORD
echo
read -s -r -p "Enter same user's password again: " USER_PASSWORD_2
echo
if [[ "$USER_PASSWORD" = "$USER_PASSWORD_2" ]]; then
    echo
else
    echo "Mismatching user's password!"
    exit 124
fi

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

# Create file systems
mkfs.vfat -F32 -n EFI "/dev/disk/by-partlabel/EFI"
mkfs.btrfs -f -L "${LINUX_PARTITION_LABEL}" /dev/mapper/root
echo
# Mounting the encrypted partition...
mount "/dev/mapper/root" "${ROOT_MNT}"
echo
# Create BTRFS subvolumes...
btrfs subvolume create "${ROOT_MNT}/@"
btrfs subvolume create "${ROOT_MNT}/@snapshots"
btrfs subvolume create "${ROOT_MNT}/@home"
btrfs subvolume create "${ROOT_MNT}/@opt"
btrfs subvolume create "${ROOT_MNT}/@srv"
btrfs subvolume create "${ROOT_MNT}/@cache"
btrfs subvolume create "${ROOT_MNT}/@images"
btrfs subvolume create "${ROOT_MNT}/@docker"
btrfs subvolume create "${ROOT_MNT}/@log"
btrfs subvolume create "${ROOT_MNT}/@spool"
btrfs subvolume create "${ROOT_MNT}/@tmp"
umount "${ROOT_MNT}"
echo
# Mounting BTRFS subvolumes...
BTRFS_SUBVOLUME_MOUNT_OPTIONS="noatime,ssd,compress=zstd:1,space_cache=v2,discard=async"
function mountBtrfsSubvolumeById() {
    mkdir -p "$2"
    mount --options "${BTRFS_SUBVOLUME_MOUNT_OPTIONS},subvolid=$1" "/dev/mapper/root" "$2"
}
function mountBtrfsSubvolumeByName() {
    mkdir -p "$2"
    mount --options "${BTRFS_SUBVOLUME_MOUNT_OPTIONS},subvol=$1" "/dev/mapper/root" "$2"
}
mountBtrfsSubvolumeByName "@"          "${ROOT_MNT}/"
mountBtrfsSubvolumeById   5            "${ROOT_MNT}/btrfsroot"
mountBtrfsSubvolumeByName "@snapshots" "${ROOT_MNT}/.snapshots"
mountBtrfsSubvolumeByName "@home"      "${ROOT_MNT}/home"
mountBtrfsSubvolumeByName "@opt"       "${ROOT_MNT}/opt"
mountBtrfsSubvolumeByName "@srv"       "${ROOT_MNT}/srv"
mountBtrfsSubvolumeByName "@cache"     "${ROOT_MNT}/var/cache"
mountBtrfsSubvolumeByName "@images"    "${ROOT_MNT}/var/lib/libvirt/images"
mountBtrfsSubvolumeByName "@docker"    "${ROOT_MNT}/var/lib/docker"
mountBtrfsSubvolumeByName "@log"       "${ROOT_MNT}/var/log"
mountBtrfsSubvolumeByName "@spool"     "${ROOT_MNT}/var/spool"
mountBtrfsSubvolumeByName "@tmp"       "${ROOT_MNT}/var/tmp"
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

# Customize /etc/pacman.conf...
sed -i \
    -e '/^#Color/s/^#//' \
    -e '/^#ParallelDownloads.*/s/^#//' \
    -e '/^ParallelDownloads.*/c\ParallelDownloads = 10' \
    -e '/^#VerbosePkgLists/s/^#//' \
    "/etc/pacman.conf"
echo
# Update pacman mirrors and then pacstrap base install
reflector --country GB --age 24 --protocol http,https --sort rate --save "/etc/pacman.d/mirrorlist"
# Pacstrapping (/etc/pacman.d/mirrorlist is going to be copied to pacman's config)...
pacstrap -K "${ROOT_MNT}" "${PACSTRAP_PACKAGES[@]}"
echo

# Generate filesystem table...
genfstab -U -p "${ROOT_MNT}" >> "${ROOT_MNT}/etc/fstab"
cat "${ROOT_MNT}/etc/fstab"
echo

# Setting up environment...
# set up locale/env: add our locale to locale.gen
sed -i -e "/^#""${LOCALE}""/s/^#//" "${ROOT_MNT}/etc/locale.gen"
# remove any existing config files that may have been pacstrapped, systemd-firstboot will then regenerate them
rm "${ROOT_MNT}"/etc/{machine-id,localtime,hostname,shadow,locale.conf} ||
systemd-firstboot \
    --root "${ROOT_MNT}" \
    --keymap="${KEYMAP}" \
    --locale="${LOCALE}" \
    --locale-messages="${LOCALE}" \
    --timezone="${TIMEZONE}" \
    --hostname="${HOST_NAME}" \
    --setup-machine-id \
    --welcome=false
arch-chroot "${ROOT_MNT}" locale-gen
echo

# Disable Copy-on-Write for virtlib images folder
arch-chroot "${ROOT_MNT}" lsattr -d /var/lib/libvirt/images/
arch-chroot "${ROOT_MNT}" chattr -VR +C /var/lib/libvirt/images/

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
echo "quiet rw rd.luks.name=${LINUX_LUKS_UUID}=root root=/dev/mapper/root rootflags=subvol=@" > "${ROOT_MNT}/etc/kernel/cmdline"
cat "${ROOT_MNT}/etc/kernel/cmdline"
echo
# create /etc/kernel/cmdline-tty
echo "quiet rw rd.luks.name=${LINUX_LUKS_UUID}=root root=/dev/mapper/root rootflags=subvol=@ systemd.unit=multi-user.target" > "${ROOT_MNT}/etc/kernel/cmdline-tty"
cat "${ROOT_MNT}/etc/kernel/cmdline-tty"
echo

# update /etc/mkinitcpio.conf
# - add the i2c-dev module for the ddcutil (external monitor brightness/contrast control)
# - change the HOOKS in mkinitcpio.conf to use systemd hooks (udev -> systemd, keymap consolefont -> sd-vconsole sd-encrypt)
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
fallback_options="--skiphooks autodetect"
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
fallback_options="--skiphooks autodetect --cmdline /etc/kernel/cmdline-tty"
EOF
echo

# read the linux UKI settings and create the folder structure otherwise mkinitcpio will crash
declare "$(grep default_uki "${ROOT_MNT}/etc/mkinitcpio.d/linux.preset")"
declare "$(grep fallback_uki "${ROOT_MNT}/etc/mkinitcpio.d/linux.preset")"
declare default_uki_dirname=$(dirname "${default_uki//\"}")
arch-chroot "${ROOT_MNT}" echo "default_uki: ${default_uki}"
arch-chroot "${ROOT_MNT}" echo "fallback_uki: ${fallback_uki}"
arch-chroot "${ROOT_MNT}" echo "default_uki_dirname: ${default_uki_dirname}"
arch-chroot "${ROOT_MNT}" mkdir -p "${default_uki_dirname}"
echo

# read the linux-lts UKI settings and create the folder structure otherwise mkinitcpio will crash
declare "$(grep default_uki "${ROOT_MNT}/etc/mkinitcpio.d/linux-lts.preset" | sed 's/default_uki=/default_lts_uki=/g')"
declare "$(grep fallback_uki "${ROOT_MNT}/etc/mkinitcpio.d/linux-lts.preset" | sed 's/fallback_uki=/fallback_lts_uki=/g')"
declare default_lts_uki_dirname=$(dirname "${default_lts_uki//\"}")
arch-chroot "${ROOT_MNT}" echo "default_lts_uki: ${default_lts_uki}"
arch-chroot "${ROOT_MNT}" echo "fallback_lts_uki: ${fallback_lts_uki}"
arch-chroot "${ROOT_MNT}" echo "default_lts_uki_dirname: ${default_lts_uki_dirname}"
arch-chroot "${ROOT_MNT}" mkdir -p "${default_lts_uki_dirname}"
echo

# Customize ${ROOT_MNT}/etc/pacman.conf...
sed -i \
    -e '/#\[multilib\]/,+1s/^#//' \
    -e '/^#Color/s/^#//' \
    -e '/^#CheckSpace/s/^#//' \
    -e '/^#ParallelDownloads.*/s/^#//' \
    -e '/^ParallelDownloads.*/c\ParallelDownloads = 10' \
    -e '/^#VerbosePkgLists/s/^#//' \
    "${ROOT_MNT}/etc/pacman.conf"
echo

# Installing base and GUI packages...
arch-chroot "${ROOT_MNT}" pacman -Sy "${PACMAN_PACKAGES[@]}" "${GPU_PACKAGES[@]}" "${DESKTOP_PACKAGES[@]}" --noconfirm --quiet
echo

# Enable services...
systemctl --root "${ROOT_MNT}" enable bluetooth keyd NetworkManager sddm systemd-resolved systemd-timesyncd
echo
# mask systemd-networkd as we will use NetworkManager instead
systemctl --root "${ROOT_MNT}" mask systemd-networkd
echo
# since we're going to use hyprland+uwsm, hypridle will run as a systemd user service
# NOTE: ~/.config/hypr/hypridle.conf must be present for the service to start properly
HYPRIDLE_PACKAGE=hypridle
if [[ " ${DESKTOP_PACKAGES[*]} " =~ [[:space:]]${HYPRIDLE_PACKAGE}[[:space:]] ]]; then
    arch-chroot "${ROOT_MNT}" su - "${USER_NAME}" --command "sudo systemctl --user enable hypridle.service"
    echo
fi

# Generating UKIs and installing Boot Loader...
arch-chroot "${ROOT_MNT}" mkinitcpio --preset linux
echo
echo "UKI images in ${default_uki_dirname}"
arch-chroot "${ROOT_MNT}" ls -lah "${default_uki_dirname}"
echo
# Remove any leftover initramfs-*.img images...
arch-chroot "${ROOT_MNT}" rm /boot/initramfs-linux.img
echo
arch-chroot "${ROOT_MNT}" mkinitcpio --preset linux-lts
echo
echo "UKI images in ${default_lts_uki_dirname}"
arch-chroot "${ROOT_MNT}" ls -lah "${default_lts_uki_dirname}"
echo
# Remove any leftover initramfs-*.img images...
arch-chroot "${ROOT_MNT}" rm /boot/initramfs-linux-lts.img
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
# TODO: check if it's needed! 🔥🔥🔥
# check the boot entry for Arch Linux has been created and its index is the first in the boot order
#arch-chroot "${ROOT_MNT}" efibootmgr
#echo

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

# Enable parallel compilation...
LOGICAL_CORES=$( grep '^processor' /proc/cpuinfo | sort -u | wc -l )
MAKE_PARALLEL_JOBS_NUMBER=$( echo "(${MAKE_PARALLEL_JOBS_LOGICAL_CORES_PERCENTAGE} * ${LOGICAL_CORES}) / 1" | bc )
sed -i -e '/^#MAKEFLAGS=.*/c\MAKEFLAGS="-j'"${MAKE_PARALLEL_JOBS_NUMBER}"'"' "/etc/makepkg.conf"
sed -i -e '/^#MAKEFLAGS=.*/c\MAKEFLAGS="-j'"${MAKE_PARALLEL_JOBS_NUMBER}"'"' "${ROOT_MNT}/etc/makepkg.conf"
cat "${ROOT_MNT}/etc/makepkg.conf" | grep "MAKEFLAGS="
echo

# bluez config
sed -i -e '/^#AutoEnable=.*/c\AutoEnable=false' "${ROOT_MNT}/etc/bluetooth/main.conf"

# YAY install...
arch-chroot "${ROOT_MNT}" su - "${USER_NAME}" --command "git clone https://aur.archlinux.org/yay.git ; cd yay ; makepkg --syncdeps --install --noconfirm ; cd .. ; rm -rf yay"
echo

# YAY update and setup packages...
arch-chroot "${ROOT_MNT}" su - "${USER_NAME}" --command "yay -Syu --noconfirm --norebuild --answerdiff=None --answeredit=None"
export AUR_PACKAGES_SAME_LINE="${AUR_PACKAGES[*]}"
arch-chroot "${ROOT_MNT}" su - "${USER_NAME}" --command "yay -S --noconfirm --norebuild --answerdiff=None --answeredit=None ${AUR_PACKAGES_SAME_LINE}"
echo


# ZSH set as default...
arch-chroot "${ROOT_MNT}" chsh --list-shells
arch-chroot "${ROOT_MNT}" chsh --shell=/usr/bin/zsh "${USER_NAME}"
echo

# Snapper ( https://wiki.archlinux.org/title/Snapper#Suggested_filesystem_layout )...
## un-mount existing /.snapshots subvolume folder
arch-chroot "${ROOT_MNT}" umount /.snapshots
arch-chroot "${ROOT_MNT}" rm -r /.snapshots
## create snapper config for / (`--no-dbus` used because in arch-chroot environment)
arch-chroot "${ROOT_MNT}" snapper --no-dbus --config root create-config /
btrfs subvolume delete "${ROOT_MNT}/.snapshots"
mkdir "${ROOT_MNT}/.snapshots"
## re-mount newly created @snaphots subvolume's folder
arch-chroot "${ROOT_MNT}" mount --all
chmod 750 "${ROOT_MNT}/.snapshots"
## check snapper configs
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
## disable automatic timeline snapshots (temporarily, to avoid snapshots to be created while setting up snapper)
systemctl --root "${ROOT_MNT}" disable snapper-timeline.timer snapper-cleanup.timer
## we shouldn't have any snapshots yet
arch-chroot "${ROOT_MNT}" snapper --no-dbus list
## create first snapshot
arch-chroot "${ROOT_MNT}" snapper --no-dbus --config root create --description "*** BEGINNING OF TIME ***"
arch-chroot "${ROOT_MNT}" snapper --no-dbus list
## enable automatic timeline snapshots (JUST FOR root CONFIG)
systemctl --root "${ROOT_MNT}" enable snapper-timeline.timer snapper-cleanup.timer


# SDDM theme...
SDDM_THEME_CONF_FILE="purple_leaves.conf"
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
sed -i \
    "s/^ConfigFile=.*/ConfigFile=Themes\/""${SDDM_THEME_CONF_FILE}""/g" \
    "${ROOT_MNT}/usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop"
sed -i \
    -e '/^ScreenWidth=.*/c\ScreenWidth="2560"' \
    -e '/^ScreenHeight=.*/c\ScreenHeight="1440"' \
    -e '/^DateFormat=.*/c\DateFormat="ddd, dd MMMM"' \
    -e '/^TranslateVirtualKeyboardButtonOn=.*/c\TranslateVirtualKeyboardButtonOn=" "' \
    -e '/^TranslateVirtualKeyboardButtonOff=.*/c\TranslateVirtualKeyboardButtonOff=" "' \
    "${ROOT_MNT}/usr/share/sddm/themes/sddm-astronaut-theme/Themes/${SDDM_THEME_CONF_FILE}"
echo


# XMonad basic setup
XMONAD_PACKAGE=xmonad
if [[ " ${DESKTOP_PACKAGES[*]} " =~ [[:space:]]${XMONAD_PACKAGE}[[:space:]] ]]; then

mkdir -p "${ROOT_MNT}/home/${USER_NAME}/.xmonad"
cat <<EOF > "${ROOT_MNT}/home/${USER_NAME}/.xmonad/xmonad.hs"
import XMonad

main = xmonad def
    { terminal           = "alacritty"
    , modMask            = mod4Mask
    , borderWidth        = 1
    , normalBorderColor  = "#363636"
    , focusedBorderColor = "darkGreen"
    }
EOF
arch-chroot "${ROOT_MNT}" chown --recursive "${USER_NAME}:${USER_NAME}" "/home/${USER_NAME}/.xmonad"
echo

fi


# guvcview.desktop file
mkdir -p "${ROOT_MNT}/home/${USER_NAME}/.local/share/applications"
cat <<EOF > "${ROOT_MNT}/home/${USER_NAME}/.local/share/applications/guvcview.desktop"
[Desktop Entry]
Version=1.0
Name=guvcview - GTK+ base UVC Viewer
Comment=
Exec=/usr/bin/guvcview
Icon=guvcview
Terminal=false
Type=Application
Categories=AudioVideo;Recorder;
EOF
arch-chroot "${ROOT_MNT}" chown --recursive "${USER_NAME}:${USER_NAME}" "/home/${USER_NAME}/.local"
echo

# Swap/swapfile setup...
# TODO: consider for hibernation (suspend-to-disk)... 🔥🔥🔥

# require password for users in the wheel group
sed -i \
    -e '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' \
    -e '/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^/# /' \
    "${ROOT_MNT}/etc/sudoers"
# disable sudo lecture message
echo "Defaults        lecture = never" > "${ROOT_MNT}/etc/sudoers.d/privacy"

# lock the root account
arch-chroot "${ROOT_MNT}" usermod --lock root
echo

sleep 3
sync
echo "Install complete. Please reboot"
echo
