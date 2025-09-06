# First boot ToDos

## GitHub SSH key

[Generating a new SSH key and adding it to the ssh-agent.](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent?platform=linux)

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
# Enter a file in which to save the key: /home/<USER_NAME>/.ssh/<HOST_NAME>_ed25519 
# Enter passphrase: set passphrase stored in your password manager as "<HOST_NAME> SSH key"
```

Adding your SSH key to the ssh-agent

```bash
# it will be included into your .bashrc file
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/<HOST_NAME>_ed25519 
```

[Adding a new SSH key to your GitHub account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account?platform=linux)

```bash
cat ~/.ssh/<HOST_NAME>_ed25519.pub | wl-copy
```

Login into your GitHub account and go to [github.com/settings/keys](https://github.com/settings/keys).

### Passphrase from script

```bash
touch "${HOME}/.ssh/askpass.sh"
chmod u+x "${HOME}/.ssh/askpass.sh"
```

Paste the following content in the newly created `$HOME/.ssh/askpass.sh`

```bash
#!/bin/sh

# pass "<HOST_NAME> SSH key"
echo "<PUT_YOUR_SSH_KEY_HERE>"
```

Add the SSH key by running (encoded in `bash` config)

```bash
SSH_ASKPASS_REQUIRE="force" SSH_ASKPASS="${HOME}/.ssh/askpass.sh" ssh-add "${HOME}/.ssh/<HOST_NAME>_ed25519 " &> /dev/null
```

### Set default editor

```bash
git config --global core.editor "nvim"
```

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
