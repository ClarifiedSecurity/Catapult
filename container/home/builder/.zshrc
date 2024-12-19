# Sourcing the general colors script
# shellcheck disable=SC1091
source /srv/scripts/general/colors.sh

# Activating Python virtual environment
export PATH=$HOME/.cargo/bin:$PATH
# shellcheck disable=SC1091
. "$HOME/.venv/bin/activate"

# Keeping history in a separate mounted folder to avoid can't save history errors when exiting the container
HISTFILE=/home/builder/.history/.zsh_history

# Enabling globbing
# This is required for next line to work correctly
setopt glob

# Path to your oh-my-zsh installation.
export ZSH="/home/builder/.oh-my-zsh"

# Load the vcs_info function for Git branch info
autoload -Uz vcs_info

# Track command start time with milliseconds
preexec() {
    cmd_start_time=$(date +%s)
}

# Update vcs_info and calculate command execution time
precmd() {
    # Update the vcs_info
    vcs_info

    # Calculate the elapsed time if the command start time is set
    if [[ -n $cmd_start_time ]]; then
        cmd_end_time=$(date +%s)

        # Calculate the difference in milliseconds
        difference=$((cmd_end_time - cmd_start_time))

        # Convert the difference to hours, minutes and seconds
        hours=$(( difference / 3600 ))
        minutes=$(( (difference % 3600) / 60 ))
        seconds=$(( difference % 60 ))

        # Format the elapsed time
        elapsed_time="${hours}h ${minutes}m ${seconds}s"

        unset cmd_start_time

    else
        elapsed_time=""
    fi

    # Checking if local branch is behind the remote
    BEHIND=$(command git rev-list --count HEAD..${git_branch}@{upstream} 2>/dev/null)
    if (( $BEHIND )); then
        git_status="⇣"
    else
        git_status=""
    fi

}

# Set the format for vcs_info (this determines how the Git branch is displayed)
zstyle ':vcs_info:git:*' formats ' (%b)'

# Define the prompt, including hostname, current directory, Git branch, and command time
PROMPT='%F{green}%m %F{blue}%1~%F{yellow}${vcs_info_msg_0_}%F{red}${git_status} %F{cyan}${elapsed_time}%f
%F{red}➜%f '

# Sourcing oh-my-zsh
. $ZSH/oh-my-zsh.sh

# Including better history search
if [ -f ~/.fzf.zsh ]; then
    . ~/.fzf.zsh
fi

# Secrets unlock script
# Can also be used with ctp secrets unlock
export ANSIBLE_VAULT_PASSWORD_FILE=$HOME/.vault/unlock-vault.sh
bash /srv/scripts/general/secrets-unlock.sh

# Running first run tasks
if [[ ! -f /tmp/first-run ]]; then

    # Running IPv(4|6) connectivity check
    /srv/scripts/general/check-connectivity.sh

    # Trusting custom certificates if they are present
    if [[ -d "/srv/custom/certificates" && "$(ls -A /srv/custom/certificates)" ]]; then

      echo -e "${C_YELLOW}Trusting custom certificates...${C_RST}"
      sudo rsync -ar /srv/custom/certificates/ /usr/local/share/ca-certificates/ --ignore-existing
      touch /tmp/trust_extra_certificates

    fi

    # Trusting personal certificates if they are present
    if [[ -d "/srv/personal/certificates" && "$(ls -A /srv/personal/certificates)" ]]; then

      echo -e "${C_YELLOW}Trusting personal certificates...${C_RST}"
      sudo rsync -ar /srv/personal/certificates/ /usr/local/share/ca-certificates/ --ignore-existing
      touch /tmp/trust_extra_certificates

    fi

    # Updating certificates if needed
    if [[ -f /tmp/trust_extra_certificates ]]; then

      sudo update-ca-certificates > /dev/null 2>/dev/null # To avoid false positive error rehash: warning: skipping ca-certificates.crt,it does not contain exactly one certificate or CRL

    fi

    # Creating the file to avoid errors when it's not present for CI pipelines for an example
    sudo touch /ssh-agent

    # Making sure that /ssh-agent has the correct permissions, required mostly for MacOS
    sudo chown -R "$(id -u)":"$(id -g)" /ssh-agent


# Initialization tasks and extra entrypoint(s) loader
bash /srv/scripts/general/docker-entrypoint.sh

    # Loading custom docker entrypoints if they are present
    if [[ -d "/srv/custom/docker-entrypoints" && "$(ls -A /srv/custom/docker-entrypoints)" ]]; then

        for custom_entrypoint in /srv/custom/docker-entrypoints/*; do
            if [ -f "$custom_entrypoint" ]; then
            # Comment in the echo line below for better debugging
            # echo -e "\n     Processing $custom_entrypoint...\n"
            "$custom_entrypoint"
            fi
        done

    fi

    # Loading default docker entrypoints
    for entrypoint in /srv/scripts/entrypoints/*; do
      if [ -f "$entrypoint" ]; then
        # Comment in the echo line below for better debugging
        # echo -e "\n     Processing $entrypoint...\n"
        "$entrypoint"
      fi
    done

    # Creating first run file
    touch /tmp/first-run

fi

echo -n -e "${C_RST}"

# Checking if completions file exists, if not then creating it
if [ -f "$HOME/autocomplete.zsh" ]; then

    echo -n -e "${C_YELLOW}"
    echo -e "Sourcing completions..."
    . $HOME/autocomplete.zsh
    echo -n -e "${C_RST}"

else

    echo -n -e "${C_YELLOW}"
    echo -e "Generating completions..."
    /srv/scripts/general/autocomplete_generator.py
    . $HOME/autocomplete.zsh
    echo -n -e "${C_RST}"

fi

# Running inventory selection script
# shellcheck disable=SC1091
. /srv/scripts/general/select-inventory.sh

# Including default zsh aliases and functions
. /srv/container/home/builder/.default_aliases

# Including custom zsh aliases and functions if they exist
if [ -f /srv/custom/container/.custom_aliases ]; then
    . /srv/custom/container/.custom_aliases
fi

# Including personal zsh aliases and functions if they exist
if [ -f /srv/personal/.personal_aliases ]; then
    . /srv/personal/.personal_aliases
fi

setopt noglob # Disabling globbing so extra quotes are not required when using Ansible patterns where * is used
setopt NO_BANG_HIST # Disabling history expansion with ! to avoid issues with Ansible commands