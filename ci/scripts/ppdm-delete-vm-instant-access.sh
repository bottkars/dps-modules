#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
echo "checking for jq...."
DEBIAN_FRONTEND=noninteractive apt-get install -qq jq < /dev/null > /dev/null
source dps-modules/ci/functions/ppdm_functions.sh
source dps-modules/ci/functions/yaml.sh



export ID=$(jq -r .id ./variable/*.json)
export PPDM_TOKEN=$(get_ppdm_token $PPDM_PASSWORD)

stop_ppdm-instant_restored-copies $ID






