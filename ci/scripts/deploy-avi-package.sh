#!/usr/bin/env bash
set -e
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation

source dps-modules/ci/functions/avi_functions.sh


AVI_TOKEN=$(get_avi_token $AVI_PASSWORD)

AVP_VERSION=$(cat avi_package/version)






printf "Uploading ${AVI_PACKAGE}${AVP_VERSION}.avp to $AVI_FQDN \n"
export AVI_FILENAME="${AVI_PACKAGE}${AVP_VERSION}.avp"
put_avi_package "avi_package/${AVI_FILENAME}"





if [[ "${DEPLOY}" == "true" ]]
    then
    printf "waiting for ${AVI_FILENAME} to become ready \n"
    until [[ $(get_avi_packages | jq -e -r 'select(.title | contains(env.WORKFLOW)).status == "ready"' 2>/dev/null) ]] || [[ $(get_avi_repository | jq -r '.[] | select(.filename | contains(env.AVI_FILENAME)).status == "Rejected"' 2> /dev/null) == true  ]]
    do
    sleep 5
    printf "."
    done
    printf "\n"

    if [[ $(get_avi_repository | jq -r '.[] | select(.filename | contains(env.AVI_FILENAME)).status == "Rejected"') ]]
    then
        printf "Package already deployed, deleting from repo"
        delete_avi_package ${AVI_FILENAME}
    else    
        export TITLE=$(get_avi_packages | jq -r 'select(.title | contains(env.WORKFLOW)).title')
        export VERSION=$(get_avi_packages | jq -r 'select(.title | contains(env.WORKFLOW)).version')    
        printf "Starting ${TITLE}  Workflow \n"
        set_avi_config "${DATA}" "${TITLE}" | jq -r .
        printf "Waiting for Installatation Start of ${AVI_PACKAGE}${AVP_VERSION} \n"
        until   [[  $(get_avi_messages | jq -r 'select(.[-1].status == "completed")' 2> /dev/null) ]] || [[ $(get_avi_packages_history | jq '.[] | select(.title | contains(env.TITLE)) | select(.version | contains(env.VERSION)).status == "completed"' 2> /dev/null) == true  ]]
            do
                printf "Reconnecting to AVE \n"
            AVI_TOKEN=$(get_avi_token $AVI_PASSWORD)
            get_avi_messages  | jq -r  '.[-1] | [.timestamp, .status, .taskId, .taskName, .content] | @tsv'
            sleep 20
        done
    fi    
fi


printf "${AVI_PACKAGE}${AVP_VERSION} deployed \n"
