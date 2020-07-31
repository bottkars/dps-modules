#!/usr/bin/env bash
set -e
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation

source dps_modules/ci/functions/avi_functions.sh
export WORKFLOW=ave-config
AVI_TOKEN=$(get_avi_token $AVE_PASSWORD)
echo "waiting for ${WORKFLOW} to become ready"

until [[ $(get_avi_packages | jq -r 'select(.title==env.WORKFLOW).status == "ready"')  ]]
do
sleep 5
printf "."
done
printf "\n"
printf "Installation System ready, now configuring AVE \n"
printf "This might take up to 40 Minutes\n"



data='{"timezone_name":"'${AVE_TIMEZONE}'", 
"common_password":"'${AVE_COMMON_PASSWORD}'" ,
"use_common_password":"true" ,
"repl_password":"'${AVE_COMMON_PASSWORD}'" ,
"rootpass":"'${AVE_COMMON_PASSWORD}'" ,
"mcpass":"'${AVE_COMMON_PASSWORD}'" ,
"viewuserpass":"'${AVE_COMMON_PASSWORD}'" ,
"admin_password_os":"'${AVE_COMMON_PASSWORD}'" ,
"root_password_os":"'${AVE_COMMON_PASSWORD}'" ,
"keystore_passphrase":"'${AVE_COMMON_PASSWORD}'" ,
"add_datadomain_config":"'${AVE_ADD_DATADOMAIN_CONFIG}'" ,
"attach_dd_with_cert":"false" ,
"accept_eula":"true" ,
"datadomain_host":"'${AVE_DATADOMAIN_HOST}'" ,
"ddboost_user":"'${AVE_DDBOOST_USER}'", 
"ddboost_user_pwd":"'${AVE_DDBOOST_USER_PWD}'" ,
"ddboost_user_pwd_cf":"'${AVE_DDBOOST_USER_PWD}'" ,
"datadomain_sysadmin":"'${AVE_DATADOMAIN_SYSADMIN}'" ,
"datadomain_sysadmin_pwd":"'${AVE_DATADOMAIN_SYSADMIN_PWD}'" ,
"datadomain_snmp_string":"public" 
}'


data=$(echo "${data}" | jq -c .)
set_avi_config $data ave-config | jq -r .

until  [[  $(get_avi_messages | jq -r 'select(.[-1].status == "completed")' 2> /dev/null) ]]
    do
    get_avi_messages  | jq -r .[-1]
    sleep 5
done



echo
echo "Done"