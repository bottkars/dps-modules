#!/usr/bin/env bash
set -e
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation

source dps-modules/ci/functions/avi_functions.sh


AVI_TOKEN=$(get_avi_token $AVI_PASSWORD)

AVP_VERSION=$(cat avi_package/version)


printf "Uploading ${AVI_PACKAGE}${AVP_VERSION}.avp to $AVI_FQDN \n"
put_avi_package "avi_package/${AVI_PACKAGE}${AVP_VERSION}.avp"




if [[ "${DEPLOY}" == "true" ]]
    then
    printf "waiting for ${AVI_PACKAGE}${AVP_VERSION} to become ready \n"
    until [[ $(get_avi_packages | jq -e -r 'select(.title | contains(env.WORKFLOW)).status == "ready"' 2>/dev/null)  ]]
    do
    sleep 5
    printf "."
    done
    printf "\n"


    export TITLE=$(get_avi_packages | jq -r 'select(.title | contains(env.WORKFLOW)).title')

    printf "Starting ${TITLE}  Workflow \n"
    set_avi_config "${DATA}" "${TITLE}" | jq -r .
    printf "Waiting for Installatation Start of ${AVI_PACKAGE}${AVP_VERSION} \n"


    # checking if package completetd or title in history as completed. do this as a av-installer restart clears current log
    until   [[  $(get_avi_messages | jq -r 'select(.[-1].status == "completed")' 2> /dev/null) ]] || [[ $(get_avi_packages_history | jq '.[] | select(.title | contains(env.TITLE)).status == "completed"') == true ]]

    #    until   [[  $(get_avi_messages | jq -r 'select(.[-1].status == "completed")' 2> /dev/null) ]] || [[ $(get_avi_messages | jq -r '. | length') == "0"  ]]
        do
    #    if [[ "$i" -gt 10 ]]
    #    then
            printf "Reconnecting to AVE \n"
    #        i=0
        AVI_TOKEN=$(get_avi_token $AVI_PASSWORD)
    #    fi    
        get_avi_messages  | jq -r  '.[-1] | [.timestamp, .status, .taskId, .taskName, .content] | @tsv'
        sleep 20
    #    echo try: $i
    #    ((i++))
    done
fi


printf "${AVI_PACKAGE} deployed \n"
