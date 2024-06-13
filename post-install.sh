#!/bin/bash

USERNAME=$1

# WARNING: This file will be executed as root.
cat <<EOF >> /home/$USERNAME/.zshrc

# Add nvm to profile
[ -z "\$NVM_DIR" ] && export NVM_DIR="\$HOME/.nvm"
source /usr/share/nvm/nvm.sh
source /usr/share/nvm/bash_completion
source /usr/share/nvm/install-nvm-exec

# Start SSH agent when opening terminal for the first time
if ! ps -ef | grep "[s]sh-agent" &>/dev/null; then
  eval \$(ssh-agent -s) &> /dev/null
fi

EOF

# Setup Docker permissions
groupadd docker
usermod -aG docker $USERNAME