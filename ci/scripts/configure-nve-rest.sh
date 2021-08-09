#!/usr/bin/env bash
set -e
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation

source dps-modules/ci/functions/avi_functions.sh

export WORKFLOW=NveConfig



if $(test -d ./deployment)
then
printf "we are on an azurerm deployment\n"
DEPLOYMENT_VERSION=$(cat deployment/version)
export NVE_PASSWORD=$(jq -r .properties.outputs.nvePasswd.value "deployment/deployment-${DEPLOYMENT_VERSION}.json")
fi
printf "Configuring Networker Virtual Edition\n"
printf "testing we can resolve the AVI at %s" "${AVI_FQDN}"
# need to add dig to image
#until dig +short -t srv "${AVI_FQDN}"; do
#    printf '.'
#    sleep 5
#done

printf "Waiting for AVI System to become ready"
until [[ 200 == $(curl -k --write-out "%{http_code}\n" --silent --output /dev/null "https://${AVI_FQDN}:443/avi/avigui.html") ]] ; do
    printf '.'
    sleep 5
done
printf "\n"


AVI_TOKEN=$(get_avi_token "${NVE_PASSWORD:-$NVE_ROOT_PASWORD}")
get_avi_packages_history | jq -r 'select(.title | contains(env.WORKFLOW))| .status == "completed"'
if [[ $(get_avi_packages_history | jq -r 'select(.title | contains(env.WORKFLOW))| .status == "completed"') == true ]]
then
    printf "${WORKFLOW)} already deployed configured, nothing to do"
else  
    echo "waiting for ${WORKFLOW} to become ready"

    until [[ $(get_avi_packages | jq -r 'select(.title==env.WORKFLOW).status == "ready"')  ]]
    do
    sleep 5
    printf "."
    done
    printf "\n"
    printf "Installation System ready, now configuring AVE \n"
    printf "This might take up to 40 Minutes\n"


    data='{"timezone_name":"'${NVE_TIMEZONE}'", 
    "admin_password_os":"'${NVE_ADMIN_PASSWORD_OS}'" ,
    "root_password_os":"'${NVE_ROOT_PASSWORD_OS}'" ,
    "snmp_string":"'${NVE_SNMP_STRING}'" ,
    "datadomain_host":"'${NVE_DATADOMAIN_HOST:-defaulthost}'" ,
    "storage_path":"'${NVE_STORAGE_PATH:-default}'" ,
    "new_ddboost_user":"'${NVE_NEW_DDBOOST_USER:-false}'" ,
    "ddboost_user":"'${NVE_DDBOOST_USER:-default}'" ,
    "ddboost_user_pwd":"'${NVE_DDBOOST_USER_PWD:-default}'" ,
    "ddboost_user_pwd_cf":"'${NVE_DDBOOST_USER_PWD_CF:-default}'" ,
    "datadomain_sysadmin":"'${NVE_DATADOMAIN_SYSADMIN:-sysadmin}'" ,
    "datadomain_sysadmin_pwd":"'${NVE_DATADOMAIN_SYSADMIN_PWD:-default}'" ,
    "tomcat_keystore_password":"'${NVE_TOMCAT_KEYSTORE_PASSWORD}'" ,
    "authc_admin_password":"'${NVE_AUTHC_ADMIN_PASSWORD}'" ,
    "install_avpasswd":"false" ,
    "add_datadomain_config":"'${NVE_ADD_DATDOMAIN_CONFIG}'"
    }'
    data=$(echo "${data}" | jq -c .)
    set_avi_config "${data}" "${WORKFLOW}" | jq -r .

    until  [[  $(get_avi_messages | jq -r 'select(.[-1].status == "completed")' 2> /dev/null) ]]
        do
        get_avi_messages  | jq -r  '.[-1] | [.timestamp, .status, .taskId, .taskName, .content] | @tsv'
        sleep 10
    done
    echo
    echo "Done"
fi