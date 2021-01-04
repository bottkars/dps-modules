#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation



echo "Evaluating if ppdm config file is passed"

if [[ -d ppdm-config ]]
then
    PPDM_CONFIG_VERSION=$(cat ./ppdm-config/version) 
    echo "Found PPDM config file, evaluating Variables from configuration Version ${PPDM_CONFIG_VERSION}"
    eval "$(jq -r 'keys[] as $key | "export \($key)=\"\(.[$key].value)\""' ./ppdm-config/tf-output-${PPDM_CONFIG_VERSION}.json)"
fi
echo

echo "Waiting for Appliance Fresh Install to become ready, this can take up to 10 Minutes"
until [[ 200 == $(curl -k --write-out "%{http_code}\n" --silent --output /dev/null "https://${PPDM_FQDN}:443/#/fresh") ]] ; do
    printf '.'
    sleep 5
done


echo "Appliance https://${PPDM_FQDN}:8443/api/v2 ready for Configuration"

echo "requesting API token for Changed Password to see if password already configured ...."




echo "requesting API token for initial setup"

source dps-modules/ci/functions/ppdm_functions.sh
if PPDM_TOKEN=$(get_ppdm_token "${PPDM_SETUP_PASSWORD}")
then

accept_ppdm_eula

echo "Retrieving initial appliance configuration Template"
    CONFIGURATION=$(get_ppdm_configuration)
    NODE_ID=$(echo $CONFIGURATION | jq -r .nodeId)  
    CONFIGURATION_ID=$(echo $CONFIGURATION | jq -r .id)

    echo "Customizing Appliance Configuration Template"
    CONFIGURATION=$(echo $CONFIGURATION | jq --arg oldpassword changeme --arg password "${PPDM_PASSWORD}" '(.osUsers[] | select(.userName == "root").newPassword) |= $password | (.osUsers[] | select(.userName == "root").password) |= $oldpassword')
    CONFIGURATION=$(echo $CONFIGURATION | jq --arg oldpassword '@ppAdm1n' --arg password "${PPDM_PASSWORD}" '(.osUsers[] | select(.userName == "admin").newPassword) |= $password | (.osUsers[] | select(.userName == "admin").password) |= $oldpassword')
    CONFIGURATION=$(echo $CONFIGURATION | jq --arg oldpassword '$upp0rt!' --arg password "${PPDM_PASSWORD}" '(.osUsers[] | select(.userName == "support").newPassword) |= $password | (.osUsers[] | select(.userName == "support").password) |= $oldpassword')
    CONFIGURATION=$(echo $CONFIGURATION | jq --arg oldpassword 'Ch@ngeme1' --arg password "${PPDM_PASSWORD}" '.lockbox.passphrase  |= $oldpassword | .lockbox.newPassphrase  |= $password')
    CONFIGURATION=$(echo $CONFIGURATION | jq --arg password "${PPDM_PASSWORD}" '.applicationUserPassword |= $password')
    CONFIGURATION=$(echo $CONFIGURATION | jq --arg timezone "Europe/Berlin - Central European Time" '.timeZone |= $timezone')
    CONFIGURATION=$(echo $CONFIGURATION | jq --arg ntpservers "${PPDM_NTP_SERVER}" '.ntpServers |= [$ntpservers]')
    CONFIGURATION=$(echo $CONFIGURATION | jq 'del(._links)')
    printf "Appliance Config State complete: "


    STATE=$(get_ppdm_config_completionstate  $CONFIGURATION_ID)
    echo "${STATE}%"
    echo "Setting Appliance"
    CONFIGURATION_REQUEST=$(set_ppdm_configurations ${CONFIGURATION_ID} "${CONFIGURATION}")
    

    printf "Appliance Config State: "
    get_ppdm_config-status  $CONFIGURATION_ID
    echo "Waiting for Appliance to reach config-status Success"
    printf "0%%"

    while [[ "SUCCESS" != $(get_ppdm_config-status  $CONFIGURATION_ID)  ]]; do
        printf "\r$(get_ppdm_config_completionstate  $CONFIGURATION_ID)%%"
        sleep 10
    done
    printf "\r100%%\n"
    echo "You can now login to the Appliance https://${PPDM_FQDN} with your Username and Password"
elif PPDM_TOKEN=$(get_ppdm_token "${PPDM_PASSWORD}")
then 
    if [[ "true" != $(get_ppdm_configuration | jq .gettingStartedCompleted ) ]]
    then
            printf "something went wrong\n"
            exit 1
    else
        printf "Appliance already configured \n"
    fi
fi    