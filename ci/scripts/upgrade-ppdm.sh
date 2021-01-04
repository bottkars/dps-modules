#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation

source dps-modules/ci/functions/ppdm_functions.sh
PPDM_VERSION=$(cat powerprotect-upgrade/version)
if PPDM_TOKEN=$(get_ppdm_token "${PPDM_PASSWORD}")
then 
    printf "uploading Upgrade"
    UPGRADE=$(upload_ppdm_upgrade powerprotect-upgrade/dellemc-ppdm-upgrade-sw-${PPDM_VERSION}.pkg)
    echo $UPGRADE | jq .
    PACKAGES=$(get_ppdm_upgrade-packages) 
    PACKAGE=$(echo "${PACKAGES//\\}"| jq --arg version "${PPDM_VERSION}" '.[] | select(.packageVersion == $version)')
    ID=$(echo $PACKAGE | jq -r .id)
    PRECHECK=$(precheck_ppdm_upgrade-packages $ID)
    until [[ "$(echo "${PRECHECK//\\}" | jq -r '.validationDetails[] | select(.resultType == "WARNING") | .message')" == "Ensure that you have a VM snapshot per documentation before starting to upgrade." ]]
    do
        sleep 5
        PRECHECK=$(precheck_ppdm_upgrade-packages $ID)
        echo "${PRECHECK//\\}" | jq '.validationDetails[] | select(.resultType == "WARNING") | .message'
    done
    echo "Setting Package State to Install"
    PACKAGE=$(echo $PACKAGE | jq '.state |= "INSTALLED"')
    upgrade_ppdm-packages $ID $PACKAGE

fi    

