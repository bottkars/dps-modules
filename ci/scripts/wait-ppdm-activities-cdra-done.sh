#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
source dps-modules/ci/functions/ppdm_functions.sh
source dps-modules/ci/functions/yaml.sh

export PPDM_TOKEN=$(get_ppdm_token $PPDM_PASSWORD)

# CDRA_STATE_FILE="$(echo "$CDRA_STATE_FILE" | envsubst)" 

while   [[ $(query_ppdm_activities 'MYSQL1' 'parentId eq null and category in ("CLOUD_PROTECT") and state in ("RUNNING")' | jq -r '.[].state == "RUNNING"') ]] 
do
    echo "CloudDR Replication running"
    sleep 60
done 

query_ppdm_activities '*' 'parentId eq null and category in ("CLOUD_PROTECT") and state in ("COMPLETED")' | jq -r '.[-1]'




