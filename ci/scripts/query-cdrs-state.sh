#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
echo "checking for jq...."
source dps-modules/ci/functions/ppdm_functions.sh
source dps-modules/ci/functions/yaml.sh

export PPDM_TOKEN=$(get_ppdm_token $PPDM_PASSWORD)
activities=$(get_ppdm_cloud-dr-server-configuration)
echo $activities | jq -r .


timestamp="$(date '+%Y%m%d.%-H%M.%S+%Z')"
export timestamp

CDRA_STATE_FILE="$(echo "$CDRS_STATE_FILE" | envsubst)" 
echo $activities | jq -r . >> cdrs-state/${CDRS_STATE_FILE}






