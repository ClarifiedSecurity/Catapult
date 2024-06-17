#!/bin/bash

set -e # exit when any command fails

# shellcheck disable=SC1091
source ./scripts/general/colors.sh

echo -e -n "${C_CYAN}"

#########################
# .make-vars validation #
#########################

# This needs to be first, because if any of the variables are not set correctly, next tasks might fail

# Checking if custom .makerc-vars.example exists and using it if it does
if [ -r custom/.makerc-vars.example  ]
then

    example_vars_file=custom/.makerc-vars.example

  else

    example_vars_file=.makerc-vars.example

fi

# Checking if .makerc-vars exists
if ! [ -r .makerc-vars  ]
then

  echo -e "${C_RED}"
  echo -e ".makerc-vars does not exist."
  echo -n -e "${C_YELLOW}"
  echo -e "You can create it with ${C_BLUE}cp $example_vars_file .makerc-vars${C_YELLOW} command."
  echo -e "If you are using custom .makerc-vars it exists in $(pwd)/.makerc-vars folder."
  echo -e "Make sure to fill out the required variables in .makerc-vars"
  echo -e "${C_RST}"
  exit 1

fi

# Checking that MAKEVAR_SUDO_COMMAND for MacOS is empty
if [[ "$(uname)" == "Darwin" && -n "${MAKEVAR_SUDO_COMMAND+x}" && -n "$MAKEVAR_SUDO_COMMAND" ]]; then

  echo -e "${C_RED}"
  echo -e "You are using MacOS, but MAKEVAR_SUDO_COMMAND is not empty in ${C_YELLOW}${ROOT_DIR}/.makerc-vars${C_RED}"
  echo -e "sudo is not usually required on MacOS, so MAKEVAR_SUDO_COMMAND should be empty"

  read -pr "Press ENTER to continue, or Ctrl + C to cancel and set the correct MAKEVAR_SUDO_COMMAND value..."
  echo -e "${C_CYAN}"

fi

##########################
# Catapult version check #
##########################

BRANCH="${MAKEVAR_CATAPULT_VERSION}"
LOCAL_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Checking for user is in the correct branch
if [ "$LOCAL_BRANCH" != "$BRANCH" ]; then

  echo -n -e "${C_YELLOW}"
  echo -e "You are not in the ${C_CYAN}$BRANCH${C_YELLOW} branch. Do you want to switch branch?"
  echo -n -e "${C_RST}"
  options=(
    "yes"
    "no"
  )

  # shellcheck disable=SC2034
  select option in "${options[@]}"; do
      case "$REPLY" in
          yes|y|1) git switch "$BRANCH"; break;;
          no|n|2) echo -e "Not changing branch"; break;;
      esac
  done

fi

# Checking if github.com is reachable
if ! curl github.com --connect-timeout 2 -s > /dev/null; then
  echo -n -e "${C_YELLOW}"
  echo -e "Cannot check for Catapult version!"
  echo -e "GitHub is not reachable"
  echo -n -e "${C_RST}"
  exit 0;
fi

# Catalpult update function
catapult_update () {

  if [ "$LOCAL_BRANCH" == "$BRANCH" ]; then

    git pull

  else

    git fetch origin "$BRANCH:$BRANCH"
    echo -e "${C_YELLOW}"
    echo -e "You are not in the ${C_CYAN}$BRANCH${C_YELLOW} branch, make sure to rebase your ${C_CYAN}$LOCAL_BRANCH${C_YELLOW} branch with: ${C_CYAN}git rebase -i origin/$BRANCH"
    echo -e "${C_RST}"

  fi

}

# Checking if the latest remote version is different than the current local version
# Using curl to get the latest version from raw file GitHub to avoid Github API rate limit
REMOTE_VERSION=$(curl --silent "https://raw.githubusercontent.com/ClarifiedSecurity/catapult/$BRANCH/version.yml" | cut -d ' ' -f 2)
LOCAL_VERSION=$(git archive "$BRANCH" version.yml | tar xO | cut -d ' ' -f 2)

# Checking if remote version is diffrent than local version
if [[ "$LOCAL_VERSION" == "$REMOTE_VERSION" ]]; then

    echo -e -n

  else

    if [ "$MAKEVAR_AUTO_UPDATE" == 1 ]; then

      echo -n -e "${C_YELLOW}"
      echo -e "Catapult version $REMOTE_VERSION is available, updating automatically..."
      if [ "$LOCAL_BRANCH" == "main" ]; then
      echo -e "Changelog: https://github.com/ClarifiedSecurity/catapult/releases/tag/v$REMOTE_VERSION"
      fi
      echo -n -e "${C_RST}"
      catapult_update

    else

      echo -n -e "${C_YELLOW}"
      echo -e "Catapult version $REMOTE_VERSION is available, do you want to update?"
      if [ "$LOCAL_BRANCH" == "main" ]; then
      echo -e "Changelog: https://github.com/ClarifiedSecurity/catapult/releases/tag/v$REMOTE_VERSION"
      fi
      echo -n -e "${C_RST}"
      options=(
        "yes"
        "no"
      )

      # shellcheck disable=SC2034
      select option in "${options[@]}"; do
          case "$REPLY" in
              yes|y|1) catapult_update; break;;
              no|n|2) echo -e "Not updating Catapult"; break;;
          esac
      done

    fi

fi

#######################
# MISC checks for QOL #
#######################

# Checking if ssh-agent is running
if [[ -z "${SSH_AUTH_SOCK}" ]]; then

  echo -e "${C_RED}"
  echo -e SSH agent is not running.
  echo -e Make sure ssh-agent is running.
  echo -e If you are running Catapult on remote server, make sure you have forwarded the SSH agent with the -A parameter...
  echo -e "${C_RST}"
  exit 1

fi

# Check if any keys exists in the ssh agent
if ssh-add -l >/dev/null 2>&1; then

  echo -n

else

  echo -e "${C_YELLOW}"
  echo -e There are no SSH keys in your ssh-agent.
  echo -e Some of the functinality will not work without SSH keys.
  read -rp "Press ENTER to continue, or Ctrl + C to cancel and load ssh keys to your agent..."
  echo -e "${C_RST}"

fi

echo -e -n "${C_RST}"