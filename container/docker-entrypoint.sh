#!/usr/bin/env bash

C_RED="\033[31m"
C_GREEN="\033[32m"
C_RST="\033[0m"

echo -n -e ${C_GREEN}

# Going into Poetry shell
export PATH=$HOME/.local/bin:$PATH
source $(poetry env info -C /srv/poetry --path)/bin/activate

# Running connectivity checks
/srv/scripts/general/connectivity-checks.sh

# Making sure that /ssh-agent has the correct permissions, required mostly for MacOS
sudo chown -R $(id -u):$(id -g) /ssh-agent

# KeePass unlocker script
# Can also be used with ctp-unlock-secrets
source /home/builder/keepass-unlocker.sh

# Copying mounted certificates to the correct location and trusting them if they are present
if [ "$(ls -A /tmp/ca-certificates)" ]; then

  sudo rsync -ar /tmp/ca-certificates/ /usr/local/share/ca-certificates/ --ignore-existing
  sudo update-ca-certificates > /dev/null 2>/dev/null # To avoid false positive error rehash: warning: skipping ca-certificates.crt,it does not contain exactly one certificate or CRL

fi

DOCKER_CONTAINER_ENTRYPOINT_CUSTOM_FILES="/srv/custom/docker-entrypoints/*.sh"
for custom_entrypoint in $DOCKER_CONTAINER_ENTRYPOINT_CUSTOM_FILES; do
  if [ -f $custom_entrypoint ]; then
    # Comment in the echo line below for better debugging
    # echo -e "\n Processing $custom_entrypoint...\n"
    source $custom_entrypoint
  fi
done

DOCKER_CONTAINER_ENTRYPOINT_FILES="/srv/scripts/entrypoints/*.sh"
for entrypoint in $DOCKER_CONTAINER_ENTRYPOINT_FILES; do
  if [ -f $entrypoint ]; then
    # Comment in the echo line below for better debugging
    # echo -e "\n Processing $entrypoint...\n"
    source $entrypoint
  fi
done

echo -n -e ${C_RST}

exec zsh