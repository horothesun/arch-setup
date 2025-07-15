#!/bin/bash
# uncomment to view debugging information 
set -xeuo pipefail

# config options
TARGET="/dev/sda"
LOCALE="en_GB.UTF-8"
KEYMAP="uk"
TIMEZONE="Europe/London"
HOSTNAME="archlinux01"
USERNAME="user"

# check if we're root
if [[ "$UID" -ne 0 ]]; then
    echo "This script needs to be run as root!" >&2
    exit 3
fi

# SHA512 hash of password. To generate, run 'mkpasswd -m sha-512' (install `whois` package), don't forget to prefix any $ symbols with \
# the entry below is the hash of 'password'
USER_PASSWORD="\$6\$/VBa6GuBiFiBmi6Q\$yNALrCViVtDDNjyGBsDG7IbnNR0Y/Tda5Uz8ToyxXXpw86XuCVAlhXlIvzy1M8O.DWFB6TRCia0hMuAJiXOZy/"
ROOT_MNT="/mnt"
LINUX_PARTITION_LABEL="LINUX"

# to fully automate the setup, change BAD_IDEA=no to yes, and enter a cleartext password for the disk encryption 
BAD_IDEA="no"
CRYPT_PASSWORD="changeme"

# packages to pacstrap
PACSTRAP_PACKAGES=(
        amd-ucode
        base
        btrfs-progs
        cryptsetup
        dosfstools
        efibootmgr
        grub
        grub-btrfs
        linux
        linux-firmware
        networkmanager
        sbctl
        sudo
        util-linux
)
PACMAN_PACKAGES=(
        alacritty
        alsa-utils
        amdgpu_top
        asciiquarium
        bash-completion
        bash-language-server
        bat
        bluez
        bluez-utils
        bluez-deprecated-tools
        pavucontrol
        btop
        cmatrix
        cliphist
        dive
        fastfetch
        firewalld
        fzf
        git
        github-cli
        git-filter-repo
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
        speedtest-cli
        starship
        stow
        tldr
        translate-shell
        tree
        ttf-jetbrains-mono-nerd
        ttf-firacode-nerd
        yq
        wl-clipboard
        wtype
        zsh
        )    
### Desktop packages #####
#HYPRLAND_PACKAGES=(
#        hypridle
#        hyprlock
#        hyprpolkitagent
#        kwalletmanager
#        kwallet-pam
#        rofi-emoji
#        rofi-wayland
#        uwsm
#        waybar
#        )
GUI_PACKAGES=(
        xfce4
        xfce4-terminal
        xfce4-goodies
        sddm
        nm-connection-editor
        mousepad
        )
#GUI_PACKAGES=(
#         plasma 
#         sddm 
#         kitty
#         nm-connection-editor
#         mousepad
#        )

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
    -n1:0:+1G -t1:ef00 -c1:EFI \
    -N2       -t2:8309 -c2:"${LINUX_PARTITION_LABEL}" \
    "${TARGET}"
sleep 2
echo
# Reload partition table...
partprobe -s "${TARGET}"
sleep 2
echo

# Encrypting root partition...
# if BAD_IDEA=yes, then pipe cryptpass and carry on, if not, prompt for it
if [[ "${BAD_IDEA}" == "yes" ]]; then
    echo -n "${CRYPT_PASSWORD}" | cryptsetup luksFormat --type luks2 --pbkdf pbkdf2 "/dev/disk/by-partlabel/${LINUX_PARTITION_LABEL}" -
    #echo -n "${CRYPT_PASSWORD}" | cryptsetup luksConvertKey --pbkdf pbkdf2 "/dev/disk/by-partlabel/${LINUX_PARTITION_LABEL}"
    echo -n "${CRYPT_PASSWORD}" | cryptsetup luksOpen "/dev/disk/by-partlabel/${LINUX_PARTITION_LABEL}" root -
else
    cryptsetup luksFormat --type luks2 --pbkdf pbkdf2 "/dev/disk/by-partlabel/${LINUX_PARTITION_LABEL}"
    #cryptsetup luksConvertKey --pbkdf pbkdf2 "/dev/disk/by-partlabel/${LINUX_PARTITION_LABEL}"
    cryptsetup luksOpen "/dev/disk/by-partlabel/${LINUX_PARTITION_LABEL}" root
fi
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
mkdir "${ROOT_MNT}/efi" -p
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
# add the local user
arch-chroot "${ROOT_MNT}" useradd -G wheel -m -p "${USER_PASSWORD}" "${USERNAME}" 
# uncomment the wheel group in the sudoers file
sed -i -e '/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^# //' "${ROOT_MNT}/etc/sudoers"
# create a basic kernel cmdline, we're using DPS so we don't need to have anything here really,
# but if the file doesn't exist, mkinitcpio will complain
echo "quiet rw" > "${ROOT_MNT}/etc/kernel/cmdline"
# update /etc/mkinitcpio.conf
# - add the i2c-dev module for the ddcutil (external monitor brightness/contrast control)
# - change the HOOKS in mkinitcpio.conf to use systemd hooks (udev -> systemd, keymap consolefont -> sd-vconsole sd-encrypt)
# Note: original HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck grub-btrfs-overlayfs)
sed -i \
    -e '/^MODULES=(.*/c\MODULES=(btrfs i2c-dev)' \
    -e '/^BINARIES=(.*/c\BINARIES=(/usr/bin/btrfs)' \
    -e '/^FILES=(.*/c\FILES=()' \
    -e '/^HOOKS=(.*/c\HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole sd-encrypt block filesystems fsck grub-btrfs-overlayfs)' \
    "${ROOT_MNT}/etc/mkinitcpio.conf"
# change the preset file to generate a Unified Kernel Image instead of an initram disk + kernel
#sed -i \
#    -e '/^#ALL_config/s/^#//' \
#    -e '/^#default_uki/s/^#//' \
#    -e '/^#default_options/s/^#//' \
#    -e 's/default_image=/#default_image=/g' \
#    -e "s/PRESETS=('default' 'fallback')/PRESETS=('default')/g" \
#    "${ROOT_MNT}/etc/mkinitcpio.d/linux.preset"
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

# read the UKI setting and create the folder structure otherwise mkinitcpio will crash
declare $(grep default_uki "${ROOT_MNT}/etc/mkinitcpio.d/linux.preset")
declare default_uki_dirname=$(dirname "${default_uki//\"}")
arch-chroot "${ROOT_MNT}" echo "default_uki: ${default_uki}"
arch-chroot "${ROOT_MNT}" echo "default_uki_dirname: ${default_uki_dirname}"
arch-chroot "${ROOT_MNT}" mkdir -p "${default_uki_dirname}"
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
arch-chroot "${ROOT_MNT}" pacman -Sy "${GUI_PACKAGES[@]}" --noconfirm --quiet
echo

# enable the services we will need on start up
# Enabling services...
systemctl --root "${ROOT_MNT}" enable systemd-resolved systemd-timesyncd NetworkManager sddm
# mask systemd-networkd as we will use NetworkManager instead
systemctl --root "${ROOT_MNT}" mask systemd-networkd
echo

# regenerate the ramdisk, this will create our UKI
# Generating UKI and installing Boot Loader...
arch-chroot "${ROOT_MNT}" mkinitcpio --preset linux
echo
echo "UKI images in ${default_uki_dirname}"
arch-chroot "${ROOT_MNT}" ls -lah "${default_uki_dirname}"
echo
# Remove any leftover initramfs-*.img images...
arch-chroot "${ROOT_MNT}" rm /boot/initramfs-linux.img /boot/initramfs-linux-fallback.img
echo

# GRUB setup...
# enable GRUB cryptodisk
arch-chroot "${ROOT_MNT}" sed -i \
    -e 's/^#GRUB_ENABLE_CRYPTODISK=y/GRUB_ENABLE_CRYPTODISK=y/g' \
    /etc/default/grub
# Move grub/ from /efi"
arch-chroot "${ROOT_MNT}" ls -lah /efi
# remove grub from /efi
arch-chroot "${ROOT_MNT}" rm -rf /efi/grub
# check the arch boot-loader folder is missing from /efi/EFI
arch-chroot "${ROOT_MNT}" ls -lah /efi/EFI
# create grub
#declare GRUB_MODULES="
#	all_video
#	boot
#	btrfs
#	cat
#	chain
#	configfile
#	echo
#	efifwsetup
#	efinet
#	ext2
#	fat
#	font
#	gettext
#	gfxmenu
#	gfxterm
#	gfxterm_background
#	gzio
#	halt
#	help
#	hfsplus
#	iso9660
#	jpeg
#	keystatus
#	loadenv
#	loopback
#	linux
#	ls
#	lsefi
#	lsefimmap
#	lsefisystab
#	lssal
#	memdisk
#	minicmd
#	normal
#	ntfs
#	part_apple
#	part_msdos
#	part_gpt
#	password_pbkdf2
#	peimage
#	png
#	probe
#	reboot
#	regexp
#	search
#	search_fs_uuid
#	search_fs_file
#	search_label
#	serial
#	sleep
#	smbios
#	squash4
#	test
#	tpm
#	true
#	video
#	xfs
#	zfs
#	zfscrypt
#	zfsinfo
#	cpuid
#	play
#	cryptodisk
#	gcry_arcfour
#	gcry_blowfish
#	gcry_camellia
#	gcry_cast5
#	gcry_crc
#	gcry_des
#	gcry_dsa
#	gcry_idea
#	gcry_md4
#	gcry_md5
#	gcry_rfc2268
#	gcry_rijndael
#	gcry_rmd160
#	gcry_rsa
#	gcry_seed
#	gcry_serpent
#	gcry_sha1
#	gcry_sha256
#	gcry_sha512
#	gcry_tiger
#	gcry_twofish
#	gcry_whirlpool
#	luks
#	lvm
#	mdraid09
#	mdraid1x
#	raid5rec
#	raid6rec
#	"
declare GRUB_MODULES="
    gcry_sha256
    part_gpt
    part_msdos
    password_pbkdf2
    tpm
    "
arch-chroot "${ROOT_MNT}" grub-install --target=x86_64-efi --efi-directory=/efi --boot-directory=/boot --bootloader-id=Linux --modules=${GRUB_MODULES}
# check the arch boot-loader folder is now present in /efi/EFI
arch-chroot "${ROOT_MNT}" ls -lah /efi/EFI
# check the grubx64.efi boot-loader's been created
arch-chroot "${ROOT_MNT}" ls -lah /efi/EFI/Linux
# check the grub/ folder is now present in /boot
arch-chroot "${ROOT_MNT}" ls -lah /boot
# check /boot/grub contains fonts/, grub.cfg, grubenv, locale/, themes/, x86_64-efi/
arch-chroot "${ROOT_MNT}" ls -lah /boot/grub
# if /boot/grub/grub.cfg is missing, create it and check again
arch-chroot "${ROOT_MNT}" grub-mkconfig --output /boot/grub/grub.cfg
arch-chroot "${ROOT_MNT}" ls -lah /boot/grub
# check the boot entry for Arch Linux has been created and its index is the first in the boot order
arch-chroot "${ROOT_MNT}" efibootmgr
echo

# TODO: test once UKI + GRUB work properly
#echo "Setting up Secure Boot..."
#if [[ "$(efivar --print-decimal --name 8be4df61-93ca-11d2-aa0d-00e098032b8c-SetupMode)" -eq 1 ]]; then
#    arch-chroot "${ROOT_MNT}" sbctl create-keys
#    arch-chroot "${ROOT_MNT}" sbctl enroll-keys --microsoft
#    arch-chroot "${ROOT_MNT}" sbctl sign --save --output /efi/EFI/Linux/grubx64.efi.signed /efi/EFI/Linux/grubx64.efi
#    #arch-chroot "${ROOT_MNT}" sbctl sign --save /efi/EFI/Linux/grubx64.efi
#    arch-chroot "${ROOT_MNT}" sbctl sign --save "${default_uki//\"}"
#else
#    echo "Not in Secure Boot setup mode. Skipping..."
#fi
#echo

# Enable services...
arch-chroot "${ROOT_MNT}" systemctl enable bluetooth keyd
echo
# ⚠️⚠️⚠️ REMINDER: enable systemd user units once logged in as a user! ⚠️⚠️⚠️
# sudo systemctl --user enable --now hypridle.service
echo

# TODO: run arch-chroot as user...
## YAY install...
#arch-chroot "${ROOT_MNT}" git clone "https://aur.archlinux.org/yay-git.git"
#arch-chroot "${ROOT_MNT}" cd yay-git
#arch-chroot "${ROOT_MNT}" makepkg -si
#arch-chroot "${ROOT_MNT}" cd ..
#arch-chroot "${ROOT_MNT}" rm -rf yay-git
#echo
#
## YAY update and setup packages...
#arch-chroot "${ROOT_MNT}" yay -Syu --noconfirm --norebuild --answerdiff=None --answeredit=None
#arch-chroot "${ROOT_MNT}" yay -S --noconfirm --norebuild --answerdiff=None --answeredit=None \
#    informant \
#    oh-my-zsh-git \
#    sddm-astronaut-theme
#echo
#
#
## ZSH set as default...
#arch-chroot "${ROOT_MNT}" chsh --list-shells
#arch-chroot "${ROOT_MNT}" chsh --shell=/usr/bin/zsh
#echo
#
## SDDM theme...
#arch-chroot "${ROOT_MNT}" cat > /etc/sddm.conf
#[Theme]
#Current=sddm-astronaut-theme
#EOF
#mkdir -p /etc/sddm.conf.d
#arch-chroot "${ROOT_MNT}" cat > /etc/sddm.conf.d/virtualkbd.conf
#[General]
#InputMethod=qtvirtualkeyboard
#EOF
#arch-chroot "${ROOT_MNT}" sed -i "s/^ConfigFile=.*/ConfigFile=Themes\/purple_leaves.conf/g" /usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop
#arch-chroot "${ROOT_MNT}" sed -i \
#    -e '/^ScreenWidth=.*/c\ScreenWidth="2560"' \
#    -e '/^ScreenHeight=.*/c\ScreenHeight="1440"' \
#    -e '/^DateFormat=.*/c\DateFormat="ddd, dd MMMM"' \
#    -e '/^TranslateVirtualKeyboardButtonOn=.*/c\TranslateVirtualKeyboardButtonOn=" "' \
#    -e '/^TranslateVirtualKeyboardButtonOff=.*/c\TranslateVirtualKeyboardButtonOff=" "' \
#    "${ROOT_MNT}/usr/share/sddm/themes/sddm-astronaut-theme/Themes/purple_leaves.conf"
#echo

# lock the root account
arch-chroot "${ROOT_MNT}" usermod -L root
echo

# ZRAM / Swap setup
# TODO: consider for hibernation (suspend-to-disk)...

echo "-----------------------------------"
echo "- Install complete. Please reboot -"
echo "-----------------------------------"
sleep 10
sync
echo
# reboot
