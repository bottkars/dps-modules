#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
echo "checking for jq...."
source dps-modules/ci/functions/ppdm_functions.sh
source dps-modules/ci/functions/yaml.sh

export PPDM_TOKEN=$(get_ppdm_token $PPDM_PASSWORD)
activities=$(query_ppdm_activities "${PPDM_QUERY}")
echo $activities | jq -r .


timestamp="$(date '+%Y%m%d.%-H%M.%S+%Z')"
export timestamp

CDR_STATE_FILE="$(echo "$CDR_STATE_FILE" | envsubst)" 
echo $activities | jq -r . >> cdr-state/${CDR_STATE_FILE}






