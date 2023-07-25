#!/bin/bash

C_RED="\033[31m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_RST="\033[0m"

echo -n -e ${C_GREEN}
echo -e "${C_GREEN}Checking clarified.core collection version...${C_RST}"

# Checking for shared roles version if MANIFEST.json exists
if [[ -f "/srv/ansible/ansible_collections/clarified/core/MANIFEST.json" ]]; then

  galaxy_local_version=$(cat /srv/ansible/ansible_collections/clarified/core/MANIFEST.json | jq -r '.collection_info.version')

fi

galaxy_remote_version_row=$(curl https://raw.githubusercontent.com/ClarifiedSecurity/clarified.core/main/clarified/core/galaxy.yml -s | grep "version:" | cut -d " " -f 2)
galaxy_remote_version=$( echo $galaxy_remote_version_row | cut -d: -f2 | xargs )
galaxy_local_version_patch=$( echo $galaxy_local_version | cut -d. -f3 )
galaxy_remote_version_patch=$( echo $galaxy_remote_version | cut -d. -f3 )

echo -e "${C_GREEN}Local clarified.core collection version:${C_RST}" $galaxy_local_version
echo -e "${C_GREEN}Remote clarified.core collection version:${C_RST}" $galaxy_remote_version

if [[ "$galaxy_local_version" != "$galaxy_remote_version" ]]; then

  echo -n -e ${C_YELLOW}
  echo -e "Remote clarified.core collection differs from local"
  echo -e "Would you like to update now?"
  echo -n -e ${C_RST}
  options=(
    "yes"
    "no"
  )

  select option in "${options[@]}"; do
  echo -n -e ${C_YELLOW}
      case "$REPLY" in
          yes) ansible-galaxy collection install -r /srv/requirements/requirements_custom.yml --force -p /srv/ansible; break;;
          no) echo -e "Not updating now"; break;;
          y) ansible-galaxy collection install -r /srv/requirements/requirements_custom.yml --force -p /srv/ansible; break;;
          n) echo -e "Not updating now"; break;;
          1) ansible-galaxy collection install -r /srv/requirements/requirements_custom.yml --force -p /srv/ansible; break;;
          2) echo -e "Not updating now"; break;;
      esac
  echo -n -e ${C_RST}
  done
fi
