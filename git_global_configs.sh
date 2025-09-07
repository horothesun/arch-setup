#!/bin/bash

# set default editor
git config --global core.editor "nvim"

# 3-way conflict style
git config --global merge.conflictStyle diff3

# auto-push tags
git config --global push.followTags true

# pretty logs
git config --global alias.lg "log --pretty='%C(bold red)%h%Creset →%C(bold yellow)%d%Creset %s %C(dim white)(%ar) %C(dim white)[%an]%Creset' --graph"

# disable branch pager
git config --global pager.branch ''

# disable config pager
git config --global pager.config ''
