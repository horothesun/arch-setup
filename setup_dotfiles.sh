#!/bin/bash

OS="arch"
HOST_NAME=$( uname --nodename )

cd
git clone git@github.com:horothesun/dotfiles.git
cd dotfiles
echo

stow --no-folding --verbose --target ~ "alacritty-${HOST_NAME}-${OS}"
stow --no-folding --verbose --target ~ "bash-${HOST_NAME}-${OS}"
stow --no-folding --verbose --target ~ "btop"
stow --no-folding --verbose --target ~ "fastfetch"
stow --no-folding --verbose --target ~ "gh"
stow --no-folding --verbose --target ~ "hypridle-${HOST_NAME}-${OS}"
stow --no-folding --verbose --target ~ "hyprland-${HOST_NAME}-${OS}"
stow --no-folding --verbose --target ~ "hyprlock-${HOST_NAME}-${OS}"
stow --no-folding --verbose --target ~ "mime-${HOST_NAME}-${OS}"
stow --no-folding --verbose --target ~ "nvim"
stow --no-folding --verbose --target ~ "rofi-${HOST_NAME}-${OS}"
stow --no-folding --verbose --target ~ "starship"
stow --no-folding --verbose --target ~ "vim"
stow --no-folding --verbose --target ~ "waybar-${HOST_NAME}-${OS}"
stow --no-folding --verbose --target ~ "zsh-${HOST_NAME}-${OS}"
echo

cd
