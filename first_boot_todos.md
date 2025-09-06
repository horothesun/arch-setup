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

## Dot-files

...
