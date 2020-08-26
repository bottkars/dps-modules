#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation

echo "checking for jq...."
DEBIAN_FRONTEND=noninteractive apt-get install -qq jq < /dev/null > /dev/null
source dps-modules/ci/functions/ppdm_functions.sh
echo "requesting API token"

export PPDM_TOKEN=$(get_ppdm_token ${PPDM_PASSWORD})
echo "Configuring Server DR"
result=$(set_ppdm_sdr-settings "${PPDD_FQDN}" "${PPDD_PATH}" "DATA_DOMAIN_SYSTEM" "true")
echo $result 

