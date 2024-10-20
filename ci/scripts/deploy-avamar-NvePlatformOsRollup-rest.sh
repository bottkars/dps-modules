#!/usr/bin/env bash
set -e
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation

source dps-modules/ci/functions/avi_functions.sh


AVI_TOKEN=$(get_avi_token $AVE_PASSWORD)

AVP_VERSION=$(cat avamar_package/version)


printf "Uploading NvePlatformOsRollup_${AVP_VERSION}.avp to $AVE_FQDN \n"
put_avi_package "avamar_package/NvePlatformOsRollup_${AVP_VERSION}.avp"
export WORKFLOW=NvePlatformOsRollup_${AVP_VERSION}




until [[ $(get_avi_packages | jq -e -r 'select(.title==env.WORKFLOW).status == "ready"' 2>/dev/null)  ]]
do
sleep 5
printf "."
done



data='{"linux_root_password":"'${AVE_PASSWORD}'"}'
set_avi_config $data $WORKFLOW | jq -r .


until  [[  $(get_avi_messages | jq -r 'select(.[-1].status == "completed")' 2> /dev/null) ]]
    do
    get_avi_messages  | jq -r  '.[-1] | [.timestamp, .status, .taskId, .taskName, .content] | @tsv'
    sleep 10
done


#     get_avi_messages  | jq -r '.[-1].status | .key'

