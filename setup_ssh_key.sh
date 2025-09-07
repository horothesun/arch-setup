#!/bin/bash

HOST_NAME="$( uname --nodename )"

read -p "Provide the SSH key email: " SSH_KEY_EMAIL
echo

read -r -p "Provide the SSH key passphrase (pass \"${HOST_NAME} SSH key\"): " SSH_KEY_PASSPHRASE
echo

# generate SSH key
ssh-keygen \
    -t ed25519 \
    -C "${SSH_KEY_EMAIL}" \
    -f "${HOME}/.ssh/${HOST_NAME}_ed25519" \
    -N "${SSH_KEY_PASSPHRASE}"
echo

# passphrase from script
cat <<EOF > "${HOME}/.ssh/askpass.sh"
#!/bin/sh

# pass "${HOST_NAME} SSH key"
echo "${SSH_KEY_PASSPHRASE}"
EOF
chmod u+x "${HOME}/.ssh/askpass.sh"

# manual steps
cat << EOF
========================
=== ⚠️ MANUAL STEPS ⚠️ ===
========================

1) Copy the public key with

    cat ~/.ssh/${HOST_NAME}_ed25519.pub | wl-copy

2) Login into your GitHub account and set the "${HOST_NAME}" SSH key in

    https://github.com/settings/keys

3) Add the SSH key to ssh-agent with (encoded in bash/zsh config)

    eval "\$(ssh-agent -s)" > /dev/null
    SSH_ASKPASS_REQUIRE="force" SSH_ASKPASS="\${HOME}/.ssh/askpass.sh" ssh-add "\${HOME}/.ssh/${HOST_NAME}_ed25519 " &> /dev/null

EOF
