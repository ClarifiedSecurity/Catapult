#!/bin/bash

set -e # exit when any command fails

# shellcheck disable=SC1091
source ./scripts/general/colors.sh

echo -n -e "${C_YELLOW}"
make customizations --no-print-directory
echo -n -e "${C_RST}"

scripts/general/configure-docker.sh

echo -n -e "${C_GREEN}"
echo -e "Preparations finished successfully"
echo -e "Run ${C_CYAN}make start${C_GREEN} to start and configure Catapult"
echo -n -e "${C_RST}"
