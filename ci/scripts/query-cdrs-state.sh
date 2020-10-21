#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
source dps-modules/ci/functions/ppdm_functions.sh
source dps-modules/ci/functions/yaml.sh

export PPDM_TOKEN=$(get_ppdm_token $PPDM_PASSWORD)
state=$(get_ppdm_cloud-dr-server-configuration)
echo $state | jq -r .


timestamp="$(date '+%Y%m%d.%H%M.%S+%Z')"
export timestamp

CDRS_STATE_FILE="$(echo "$CDRS_STATE_FILE" | envsubst)" 
echo $state | jq -r . >> cdrs-state/${CDRS_STATE_FILE}


if  [[ $(echo $state | jq -r '.cdrsConnectivityState == "NO_CONNECTION"') ]]
then
    echo "Cloud Desaster Recovery Services Suspended on Azure"
    echo $state  | jq -r . >> cdrs-state/${CDRS_STATE_FILE}
else
    echo "Cloud Desaster Recovery Services running on Azure"
   echo $state | jq -r . >> cdrs-state/running_${CDRS_STATE_FILE} 
fi   






