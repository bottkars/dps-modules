#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
echo "checking for jq...."
DEBIAN_FRONTEND=noninteractive apt-get install -qq jq < /dev/null > /dev/null
source dps-modules/ci/functions/ppdm_functions.sh
source dps-modules/ci/functions/yaml.sh


export REF_VERSION=$(cat ./variable/version)


break
echo $request | jq -r .

INSTANT_FILE="$(echo "$INSTANT_FILE" | envsubst)" 
echo $request | jq -r . >> instant_access/${INSTANT_FILE}



