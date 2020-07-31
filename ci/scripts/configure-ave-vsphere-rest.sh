#!/usr/bin/env bash
set -e
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation

source dps_modules/ci/functions/ave_functions.sh




WORKFLOW=AveConfig


break
exit 1

echo "waiting for AVAMAR $WORKFLOW  to be available"
### get the SW Version
unset AVE_CONFIG
until [[ ! -z $AVE_CONFIG ]]
do
AVE_CONFIG=$(avi-cli-run --user root --password "${AVE_PASSWORD}" \
 --listrepository localhost 2> /dev/null  \
 | grep ${WORKFLOW} | awk '{print $1}' )
sleep 5
printf "."
done
printf "\n"

echo "waiting for ave-config to become ready"
until [[ $(avi-cli-run --user root --password "${AVE_PASSWORD}" \
 --listhistory localhost | grep ave-config | awk  '{print $5}') == "ready" ]]
do
printf "."
sleep 5
done
printf "Installation System ready, now configuring AVE \n"
printf "This might take up to 40 Minutes\n"




INSTALL_PID=$(avi-cli-start --user root --password "${AVE_PASSWORD}" --install ave-config  \
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
    --input add_datadomain_config=${AVE_ADD_DATADOMAIN_CONFIG} \
    --input attach_dd_with_cert=false \
    --input accept_eula=true \
    --input datadomain_host=${AVE_DATADOMAIN_HOST} \
    --input ddboost_user=${AVE_DDBOOST_USER} \
    --input ddboost_user_pwd=${AVE_DDBOOST_USER_PWD} \
    --input ddboost_user_pwd_cf=${AVE_DDBOOST_USER_PWD} \
    --input datadomain_sysadmin=${AVE_DATADOMAIN_SYSADMIN} \
    --input datadomain_sysadmin_pwd=${AVE_DATADOMAIN_SYSADMIN_PWD} \
    --input datadomain_snmp_string=public \
        localhost)

echo "Running Installer ave-install with PID $INSTALL_PID"
# we loop the web interface, as we would switch password during install
until [[ 200 == $(curl -k --write-out "%{http_code}\n" --silent --output /dev/null "https://${AVE_FQDN}:/dtlt/home.html") ]] ; do
    printf '.'
    sleep 5
done

printf "\n"
# switch password to new installer
export AVE_PASSWORD=${AVE_COMMON_PASSWORD}
printf "Avamar Virtual Appliance https://${AVE_FQDN} is ready for use now !\n but waiting for installer to finalize"

echo "Waiting for ave-install completed"
until [[ $(avi-cli-run --user root --password "${AVE_PASSWORD}" --listhistory localhost \
 | grep ave-install \
 | awk '{print $5}') == "completed" ]]
do
    printf "."
    sleep 5
done

echo
echo "Done"