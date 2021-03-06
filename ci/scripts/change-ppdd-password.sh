#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x

figlet DPS Automation

echo "checking for jq...."
DEBIAN_FRONTEND=noninteractive apt-get install -qq jq < /dev/null > /dev/null

source dps-modules/ci/functions/ppdd_functions.sh
echo "getting PPDD token"
export PPDD_TOKEN=$(get_ppdd_token ${PPDD_SETUP_PASSWORD})
echo "getting PPDD System ID"
export PPDD_SYSTEM_ID=$(get_ppdd_system_id)
echo "Setting sysadmin password using REST API"
pwchange=$(set_ppdd_user_password ${PPDD_USERNAME} ${PPDD_SETUP_PASSWORD} "${PPDD_PASSWORD}")
echo "Done changing Password"

