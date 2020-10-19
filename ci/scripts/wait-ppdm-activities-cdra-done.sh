#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
echo "checking for jq...."
source dps-modules/ci/functions/ppdm_functions.sh
source dps-modules/ci/functions/yaml.sh

export PPDM_TOKEN=$(get_ppdm_token $PPDM_PASSWORD)

# CDRA_STATE_FILE="$(echo "$CDRA_STATE_FILE" | envsubst)" 

while   [[ $(query_ppdm_activities 'CLOUD_PROTECT' | jq -r '.[].state == "RUNNING"') ]] 
do
    echo "CloudDR Replication running"
    sleep 60
done 






