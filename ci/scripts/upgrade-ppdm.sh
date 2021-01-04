#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation



if PPDM_TOKEN=$(get_ppdm_token "${PPDM_PASSWORD}")
then 
    printf "uploading Upgrade"
fi    