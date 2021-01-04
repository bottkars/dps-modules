#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation

source dps-modules/ci/functions/ppdm_functions.sh
PPDM_VERSION=$(cat powerprotect-upgrade/version)
govc about
if PPDM_TOKEN=$(get_ppdm_token "${PPDM_PASSWORD}")
then 
    printf "uploading Upgrade"
    UPGRADE=$(upload_ppdm_upgrade /home/bottk/dellemc-ppdm-upgrade-sw-${PPDM_VERSION}.pkg)
    echo $UPGRADE | jq .
fi    