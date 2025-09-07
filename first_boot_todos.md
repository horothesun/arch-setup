# First boot ToDos

## GitHub SSH key

Run

```bash
./setup_ssh_key.sh
```

and follow the manual steps.

### Set default editor

```bash
git config --global core.editor "nvim"
```

... https://github.com/horothesun/macos-setup/blob/master/git_global_configs.sh ...

## Dot-files

```bash
cd
git clone git@github.com:horothesun/dotfiles.git
cd dotfiles
stow --no-folding --verbose --target ~ alacritty-<HOST_NAME>-<OS>
stow --no-folding --verbose --target ~ bash-<HOST_NAME>-<OS>
stow --no-folding --verbose --target ~ btop
stow --no-folding --verbose --target ~ fastfetch
stow --no-folding --verbose --target ~ gh
stow --no-folding --verbose --target ~ hypridle-<HOST_NAME>-<OS>
stow --no-folding --verbose --target ~ hyprland-<HOST_NAME>-<OS>
stow --no-folding --verbose --target ~ hyprlock-<HOST_NAME>-<OS>
stow --no-folding --verbose --target ~ mime-<HOST_NAME>-<OS>
stow --no-folding --verbose --target ~ nvim
stow --no-folding --verbose --target ~ rofi-<HOST_NAME>-<OS>
stow --no-folding --verbose --target ~ starship
stow --no-folding --verbose --target ~ vim
stow --no-folding --verbose --target ~ waybar-<HOST_NAME>-<OS>
stow --no-folding --verbose --target ~ zsh-<HOST_NAME>-<OS>
```

## Hypridle setup (TBD)

...

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

Swap `` ` `` / `~` with `§` / `±` keys using the `keyd` remapping daemon.

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

## KDE Wallet (required by Brave browser)

Follow [this guide](https://wiki.archlinux.org/title/KDE_Wallet#Unlocking_KWallet_automatically_in_a_window_manager)
to setup a default KDE Wallet named `kdewallet` with same password of your user and automatically unlocked at startup
(currently defined in hyprland autostart).

> TBC: it might be necessary to let Brave create its own KDE Wallet (named `Default keyring`) at first startup, then to remove it.

## Brave browser

Launch it, set `brave://flags/#ozone-platform-hint` to "Wayland" (to fix fractional scaling font issues) and restart.

Set `brave://flags/#scrollable-tabstrip` to "Enabled" to actually disable the feature.

## 🔒 Password Store

Follow private notes.

## NeoVim

Install the `vim-plug` plugin manager ([guide](https://github.com/junegunn/vim-plug#neovim)), then install `nvim` plugins with

```bash
nvim -c "PlugInstall|qa" ; nvim
```

## IntelliJ Idea IDE

Install IntelliJ Idea Community Edition via the JetBrains Toolbox. Set VM options with

- `-Xmx16384m`
- `-Dawt.toolkit.name=WLToolkit` (enable Wayland [blog](https://blog.jetbrains.com/platform/2024/07/wayland-support-preview-in-2024-2/))
