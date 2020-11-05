#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
source dps-modules/ci/functions/ppdm_functions.sh


if [[ -d ppdm-config ]]
then
    PPDM_CONFIG_VERSION=$(cat ./ppdm-config/version) 
    echo "Found PPDM confiog file, evaluating Variables from vonfiguration Version ${PPDM_CONFIG_VERSION}"
    eval "$(jq -r 'keys[] as $key | "export \($key)=\"\(.[$key].value)\""' ./ppdm-config/tf-output-${PPDM_CONFIG_VERSION}.json)"
    export INVENTORY_FQDN="${DDVE_PRIVATE_FQDN::-1}"
fi
echo

echo "requesting API token"

export PPDM_TOKEN=$(get_ppdm_token ${PPDM_PASSWORD})
echo "Configuring Server DR"
result=$(set_ppdm_sdr-settings "${PPDD_FQDN:-$PPDM_PRIVATE_FQDN}" "${PPDD_PATH}" "DATA_DOMAIN_SYSTEM" "true")
echo $result 

