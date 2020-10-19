#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
echo "checking for jq...."
source dps-modules/ci/functions/ppdm_functions.sh
source dps-modules/ci/functions/yaml.sh

export PPDM_TOKEN=$(get_ppdm_token $PPDM_PASSWORD)
state=$(get_ppdm_cloud-dr-server-configuration)
echo $activities | jq -r .


timestamp="$(date '+%Y%m%d.%-H%M.%S+%Z')"
export timestamp

CDRS_STATE_FILE="$(echo "$CDRS_STATE_FILE" | envsubst)" 
echo $state | jq -r . >> cdrs-state/${CDRS_STATE_FILE}


if  [[ $(echo $state | jq -r '.cdrsConnectivityState == "NO_CONNECTION"') ]]
then
    echo $state | jq -r . >> cdra-state/${CDRA_STATE_FILE}
else
   echo $state | jq -r . >> cdra-state/running_${CDRA_STATE_FILE} 
fi   






