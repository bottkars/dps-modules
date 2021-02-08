#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
source dps-modules/ci/functions/ppdm_functions.sh
source dps-modules/ci/functions/yaml.sh

export PPDM_TOKEN=$(get_ppdm_token $PPDM_PASSWORD)


echo "Querying activities with Query '${PPDM_QUERY}' and Filter '${PPDM_FILTER}'"
activities=$(query_ppdm_activities "'${PPDM_QUERY}'" "'${PPDM_FILTER}'")
echo $activities | jq -r '.[]'


export timestamp="$(date '+%Y%m%d.%-H%M.%S')"

CDRA_STATE_FILE="$(echo "$CDRA_STATE_FILE" | envsubst)" 

if  [[ $(echo $activities| jq -r '.[-1].state == "RUNNING"') == "true" ]]
then
    echo "Cloud Desaster Recovery Backup Running ! at ${timestamp}"
    echo $activities | jq -r . >> cdra-state/${CDRA_STATE_FILE}
else
    echo "No Cloud Desaster Recovery Backup Running ! ${timestamp}"
    cp cdra-active/*.json cdra-state/
fi   






