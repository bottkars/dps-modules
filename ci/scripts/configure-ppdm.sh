#!/bin/bash
set -eu

echo "installing jq...."
DEBIAN_FRONTEND=noninteractive apt-get install -qq jq < /dev/null > /dev/null

echo "requesting API token"

source dps_modules/ci/functions/ppdm_functions.sh
TOKEN=$(get_token ${PPDM_SETUP_PASSWORD})

echo "Retrieving initial appliance configuration Template"
CONFIGURATION=$(get_configuration "${TOKEN}")
NODE_ID=$(echo $CONFIGURATION | jq -r .nodeId)  
CONFIGURATION_ID=$(echo $CONFIGURATION | jq -r .id)

echo "Customizing Appliance Configuration Template"
CONFIGURATION=$(echo $CONFIGURATION | jq --arg oldpassword changeme --arg password ${PPDM_PASSWORD} '(.osUsers[] | select(.userName == "root").newPassword) |= $password | (.osUsers[] | select(.userName == "root").password) |= $oldpassword')
CONFIGURATION=$(echo $CONFIGURATION | jq --arg oldpassword '@ppAdm1n' --arg password ${PPDM_PASSWORD} '(.osUsers[] | select(.userName == "admin").newPassword) |= $password | (.osUsers[] | select(.userName == "admin").password) |= $oldpassword')
CONFIGURATION=$(echo $CONFIGURATION | jq --arg oldpassword '$upp0rt!' --arg password ${PPDM_PASSWORD} '(.osUsers[] | select(.userName == "support").newPassword) |= $password | (.osUsers[] | select(.userName == "support").password) |= $oldpassword')
CONFIGURATION=$(echo $CONFIGURATION | jq --arg oldpassword 'Ch@ngeme1' --arg password ${PPDM_PASSWORD} '.lockbox.passphrase  |= $oldpassword | .lockbox.newPassphrase  |= $password')
CONFIGURATION=$(echo $CONFIGURATION | jq --arg password ${PPDM_PASSWORD} '.applicationUserPassword |= $password')
CONFIGURATION=$(echo $CONFIGURATION | jq --arg timezone "Europe/Berlin - Central European Time" '.timeZone |= $timezone')
CONFIGURATION=$(echo $CONFIGURATION | jq --arg ntpservers "192.168.1.1" '.ntpServers |= [$ntpservers]')
CONFIGURATION=$(echo $CONFIGURATION | jq 'del(._links)')
printf "Appliance Config State complete: "


STATE=$(get_config_completionstate $TOKEN $CONFIGURATION_ID)
echo "${STATE}%"
echo "Setting Appliance"
CONFIGURATION_REQUEST=set_configuration ${TOKEN} ${CONFIGURATION_ID} "${CONFIGURATION}"
  

printf "Appliance Config State: "
get_config_state $TOKEN $CONFIGURATION_ID
echo "Waiting for appliance to reach Config State Success"
printf "0%%"

while [[ "SUCCESS" != $(get_config_state $TOKEN $CONFIGURATION_ID)  ]]; do
    printf "\r$(get_config_completionstate $TOKEN $CONFIGURATION_ID)%%"
done
printf "\r100%%\n"
echo "You can now login to the Appliance https://${PPDM_FQDN} with your Username and Password"
