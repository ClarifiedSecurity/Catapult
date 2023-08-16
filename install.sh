#!/bin/bash

set -e # exit when any command fails

C_RED="\033[31m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_MAGENTA="\033[95m"
C_RST="\033[0m"

# Check if script is run with sudo
if [ $EUID -eq 0 ]; then

    echo -e ${C_RED}
    echo -e "Don't run this script with sudo, it will ask for sudo password when needed."

    read -p "Press Ctrl + C to cancel or Press any key to continue..."
    echo -e ${C_RST}

fi

makerc-vars-creator() {

# Checking if .makerc-vars already exists and asking for an overwrite
if [ -f .makerc-vars ]; then

    echo -e ${C_YELLOW}
    echo -e ".makerc-vars already exists, do you want to overwrite it?"

    options=(
        "Yes"
        "No"
    )

    select option in "${options[@]}"; do
        case "$REPLY" in
            yes) cp -f .makerc-vars.example .makerc-vars; break;;
            no) echo -e "Not overwriting .makerc-vars"; break;;
            y) cp -f .makerc-vars.example .makerc-vars; break;;
            n) echo -e "Not overwriting .makerc-vars"; break;;
            1) cp -f .makerc-vars.example .makerc-vars; break;;
            2) echo -e "Not overwriting .makerc-vars"; break;;
        esac
    done

    echo -n -e ${C_RST}

else

    cp -f .makerc-vars.example .makerc-vars

fi

}

while [ ! -f .makerc-vars ]; do

    echo -e ${C_RED}
    echo -e "$(pwd)/.makerc-vars not found"
    echo -e ${C_YELLOW}
    echo -e "Do you want to create your .makerc-vars file from the .makerc-vars.example file?"

    options=(
        "Yes"
        "No, I'm using custom .makerc-vars"
    )

    select option in "${options[@]}"; do
        case "$REPLY" in
            yes) makerc-vars-creator; break;;
            no) read -p "Make sure your $(pwd)/.makerc-vars exists and press any key to continue"; break;;
            y) makerc-vars-creator; break;;
            n) read -p "Make sure your $(pwd)/.makerc-vars exists and press any key to continue"; break;;
            1) makerc-vars-creator; break;;
            2) read -p "Make sure your $(pwd)/.makerc-vars exists and press any key to continue"; break;;
        esac
    done

    echo -n -e $C_RST

done

# MacOS
if [[ $(uname) == "Darwin" ]]; then

  echo -n -e ${C_MAGENTA}
  echo -e "Removing MacOS sudo requirement for Catapult..."
  echo -n -e ${C_RST}

  sed -i "" "s#MAKEVAR_SUDO_COMMAND.*#MAKEVAR_SUDO_COMMAND :=#" .makerc-vars

  echo -n -e ${C_MAGENTA}
  echo -e "Installing Homebrew..."
  echo -n -e ${C_RST}
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo -n -e ${C_MAGENTA}
  echo -e "Installing MacOS packages with homebrew..."
  echo -n -e ${C_RST}

  brew install git git-lfs make jq curl md5sha1sum

fi

# Linux
if [[ $(uname) == "Linux" ]]; then

    if ! [ -x "$(command -v sudo)" ]; then

    echo -e ${C_RED}
    echo -e "sudo is not installed, install it and run this script again."
    echo -e ${C_RST}
    exit 0

    fi

    # Debian
    if grep -q "debian" /etc/os-release; then

        echo -n -e ${C_MAGENTA}
        echo -e "Installing required deb packages..."
        echo -n -e ${C_RST}

        sudo -E apt-get update
        sudo -E apt-get install git git-lfs make jq curl sudo gpg ssh -y

        if [ -n "$WSL_DISTRO_NAME" ]; then

            sudo -E apt-get update
            sudo -E apt-get install keychain -y

        fi

    # Arch
    elif grep -q "arch" /etc/os-release; then

        echo -n -e ${C_MAGENTA}
        echo -e "Installing required pacman packages..."
        echo -n -e ${C_RST}

        sudo -E pacman -S git git-lfs make jq curl sudo --noconfirm

    # Other
    else

        echo -n -e ${C_YELLOW}
        echo -e "Unsupported OS"
        echo -e "Please install git."
        echo -e "Please install git LFS for your OS and initialize it."
        echo -e "Please install curl"
        echo -e "Please install jq"
        echo -n -e ${C_RST}

    fi

fi

echo -n -e ${C_MAGENTA}
echo -e "Configuring githooks & LFS..."
echo -n -e ${C_RST}

touch ~/.gitconfig
git config core.hooksPath .githooks
git lfs install

make prepare