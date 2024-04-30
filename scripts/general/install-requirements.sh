#!/bin/bash

set -e # exit when any command fails

# shellcheck disable=SC1091
source /srv/scripts/general/colors.sh

export PATH=$HOME/.cargo/bin:$PATH
REQUIREMENTS_FILES="requirements*.yml" # Requirements file catch-all variable

# Activating the virtual environment
# shellcheck disable=SC1091
source "$HOME/.venv/bin/activate"

echo -e "\033[32mGetting requirements from /srv/requirements folder...\033[0m"
cd /srv/requirements

# Installing all requirements based on requirements*.yml files and also installes all Python requirements based on requirements.txt
install_all_requirements () {

# Installing Python requirements based on requirements.txt
uv pip install -r /srv/defaults/requirements.txt

# Looping over all requirements.yml files in the folder and running install on them
for requirement_file in $REQUIREMENTS_FILES; do

  # Default requirements are installed in the ~/ansible folder under the project
  if [[ $requirement_file == requirements.yml ]]; then
    echo -e "\033[33mInstalling roles from $(readlink -f $requirement_file)\033[0m"
    ansible-galaxy role install -r $requirement_file --force --no-deps -p ~/ansible

    echo -e "\033[33mInstalling collections from $(readlink -f $requirement_file)\033[0m"
    ansible-galaxy collection install -r $requirement_file --force --no-deps -p ~/ansible --no-cache --clear-response-cache
  else
    echo -e "\033[33mInstalling roles from $(readlink -f $requirement_file)\033[0m"
    ansible-galaxy role install -r $requirement_file --force --no-deps -p /srv/ansible

    echo -e "\033[33mInstalling collections from $(readlink -f $requirement_file)\033[0m"
    ansible-galaxy collection install -r $requirement_file --force --no-deps -p /srv/ansible --no-cache --clear-response-cache
  fi
done
}

# Installing only requirements in requirements.yml file and Python requirements based on requirements.txt
install_default_requirements () {

# Looping over all requirements.yml files in the folder and running install on them
for requirement_file in $REQUIREMENTS_FILES; do

  # Default requirements are installed in the ~/ansible folder under the project
  if [[ $requirement_file == requirements.yml ]]; then
    echo -e "\033[33mInstalling roles from $(readlink -f $requirement_file)\033[0m"
    ansible-galaxy role install -r $requirement_file --force --no-deps -p ~/ansible

    echo -e "\033[33mInstalling collections from $(readlink -f $requirement_file)\033[0m"
    ansible-galaxy collection install -r $requirement_file --force --no-deps -p ~/ansible --no-cache --clear-response-cache
  fi
done
}

# Installing only requirements in requirements*.yml files and not the default requirements.yml file
install_extra_requirements () {

# Looping over all requirements.yml files in the folder and running install on them
for requirement_file in $REQUIREMENTS_FILES; do

  # Default requirements are installed in the ~/ansible folder under the project
  if [[ $requirement_file != requirements.yml ]]; then
    echo -e "\033[33mInstalling roles from $(readlink -f $requirement_file)\033[0m"
    ansible-galaxy role install -r $requirement_file --force --no-deps -p /srv/ansible

    echo -e "\033[33mInstalling collections from $(readlink -f $requirement_file)\033[0m"
    ansible-galaxy collection install -r $requirement_file --force --no-deps -p /srv/ansible --no-cache --clear-response-cache
  fi
done
}

if [[ "$1" == 'ALL' ]]; then
  install_all_requirements
fi

if [[ "$1" == 'DEFAULT' ]]; then
  install_default_requirements
fi

if [[ "$1" == 'EXTRA' ]]; then
  install_extra_requirements

  # Creating ansible to project root, to signify that the requirements have been installed.
  # Because when not using extra roles/collections the ansible folder is not created.
  mkdir -p /srv/ansible

fi