#!/usr/bin/env bash
set -e
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation

source dps-modules/ci/functions/avi_functions.sh


AVI_TOKEN=$(get_avi_token $AVI_PASSWORD)

AVP_VERSION=$(cat avi_package/version)


printf "Uploading UpgradeClientDownloads-${AVP_VERSION}.avp to $AVI_FQDN"
put_avi_package "avi_package/UpgradeClientDownloads-${AVP_VERSION}.avp"
export WORKFLOW=upgrade-client-downloads

break


until [[ $(get_avi_packages | jq -e -r 'select(.title==env.WORKFLOW).status == "ready"' 2>/dev/null)  ]]
do
sleep 5
printf "."
done



data="{}"
set_avi_config $data upgrade-client-downloads | jq -r .


until  [[  $(get_avi_messages | jq -r 'select(.[-1].status == "completed")' 2> /dev/null) ]]
    do
    get_avi_messages  | jq -r  '.[-1] | [.timestamp, .status, .taskId, .taskName, .content] | @tsv'
    sleep 10
done


#     get_avi_messages  | jq -r '.[-1].status | .key'

