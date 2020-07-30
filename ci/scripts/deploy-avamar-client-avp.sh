#!/usr/bin/env bash
set -e
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation

source dps_modules/ci/functions/ave_functions.sh




WORKFLOW=AveConfig


curl -k "${AVE_UPGRADE_CLIENT_DOWNLOADS_URL}" --output /space/avamar/repo/packages/${AVE_UPGRADE_CLIENT_DOWNLOADS_PACKAGE}


avi-cli-start --user root --password "${AVE_PASSWORD}" --install ave-config  \
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
        localhost

until [[ 200 == $(curl -k --write-out "%{http_code}\n" --silent --output /dev/null "https://${AVE_FQDN}:443/dtlt") ]] ; do
    printf '.'
    sleep 5
done

printf "\n"

printf "Avamar Virtual Appliance https://${AVE_FQDN}/aui is ready !\n"

### from here we will stzart to upload client configs :-)
#echo
#echo "Networker Appliance https://${NVE_FQDN}:9000 is ready !"

## validate new_ddboost_user over ddboost_user


