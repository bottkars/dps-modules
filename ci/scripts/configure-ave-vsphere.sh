#!/usr/bin/env bash
set -e
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation

source dps_modules/ci/functions/ave_functions.sh




WORKFLOW=AveConfig
echo "waiting for AVAMAR $WORKFLOW  to be available"
### get the SW Version
unset AVE_CONFIG
until [[ ! -z $AVE_CONFIG ]]
do
AVE_CONFIG=$(avi-cli --user root --password "${AVE_SETUP_PASSWORD}" \
 --listrepository localhost 2> /dev/null  \
 | grep ${WORKFLOW} | awk '{print $1}' )
sleep 5
printf "."
done


echo "waiting for ave-config to become ready"
until [[ $(avi-cli --user root --password "${AVE_SETUP_PASSWORD}" \
 --listhistory localhost | grep ave-config | awk  '{print $5}') == "ready" ]]
do
printf "."
sleep 5
done



AVE_TIMEZONE="Europe/Berlin"
AVE_COMMON_PASSWORD="Change_Me12345_"
avi-cli --user root --password "${AVE_PASSWORD}" --install ave-config  \
    --input timezone_name="${AVE_TIMEZONE}" \
    --input common_password=${AVE_COMMON_PASSWORD} \
    --input use_common_password=true \
    --input repl_password=${AVE_COMMON_PASSWORD} \
    --input rootpass=${AVE_COMMON_PASSWORD} \
    --input mcpass=${AVE_COMMON_PASSWORD} \
    --input viewuserpass=${AVE_COMMON_PASSWORD} \
    --input admin_password_os=${AVE_COMMON_PASSWORD} \
    --input root_password_os=${AVE_COMMON_PASSWORD} \
    --input keystore_passphrase=${AVE_COMMON_PASSWORD} \
    --input add_datadomain_config=false
    --input accept_eula=true \
    localhost
#until [[ 200 == $(curl -k --write-out "%{http_code}\n" --silent --output /dev/null "https://${NVE_FQDN}:9000") ]] ; do
#    printf '.'
#    sleep 5
#done

#echo
#echo "Networker Appliance https://${NVE_FQDN}:9000 is ready !"

## validate new_ddboost_user over ddboost_user

