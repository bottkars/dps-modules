#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
echo "checking for jq...."
source dps-modules/ci/functions/ppdm_functions.sh
source dps-modules/ci/functions/yaml.sh

export PPDM_TOKEN=$(get_ppdm_token $PPDM_PASSWORD)
activities=$(query_ppdm_activities "${PPDM_QUERY}")
echo $activities | jq -r '.[]'


timestamp="$(date '+%Y%m%d.%-H%M.%S+%Z')"
export timestamp

CDRA_STATE_FILE="$(echo "$CDRA_STATE_FILE" | envsubst)" 

if  [[ $(echo $activities| jq -r '.[].state == "RUNNING"') ]] 
then
    echo "Cloud Desaster Recovery Backup Running !"
    echo $activities | jq -r . >> cdra-state/${CDRA_STATE_FILE}
else
echo "No Cloud Desaster Recovery Backup Running !"
   echo $activities | jq -r . >> cdra-state/no_${CDRA_STATE_FILE} 
fi   






