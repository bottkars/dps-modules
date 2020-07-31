#!/usr/bin/env bash
set -e
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation

source dps_modules/ci/functions/avi_functions.sh

AVP_VERSION=$(echo $AVE_UPGRADE_CLIENT_DOWNLOADS_PACKAGE  | cut -d "-" -f2-)
AVP_VERSION=${AVP_VERSION//.avp}
AVP_VERSION=${AVP_VERSION/-/.}
echo "Checking if ${AVE_UPGRADE_CLIENT_DOWNLOADS_PACKAGE} is already installed"
set +e
if [[ $AVP_VERSION == "$(avi-cli-run --user root --password "${AVE_PASSWORD}" --listhistory localhost  | grep upgrade-client-downloads |  awk '{print $3}')" ]]
    then
        echo "${AVE_UPGRADE_CLIENT_DOWNLOADS_PACKAGE} already installed, nothing to do here"
    else
        set -e
        echo "Downloading ${AVE_UPGRADE_CLIENT_DOWNLOADS_PACKAGE} to avamar Server Repo"
        avi-run-bashscript curl -k "'${AVE_UPGRADE_CLIENT_DOWNLOADS_URL}'" --output /space/avamar/repo/packages/${AVE_UPGRADE_CLIENT_DOWNLOADS_PACKAGE}

        echo "Waiting for Package ${AVE_UPGRADE_CLIENT_DOWNLOADS_PACKAGE} to become available for Installation"
        until [[ $(avi-cli-run --user root --password "${AVE_PASSWORD}" --listrepository localhost \
        | grep ${AVE_UPGRADE_CLIENT_DOWNLOADS_PACKAGE} \
        | awk '{print $5}') == "Accepted" ]]
        do
            printf "."
            sleep 5
        done
        printf "\n"
        echo "${AVE_UPGRADE_CLIENT_DOWNLOADS_PACKAGE} Accepted"
        echo "Starting Installation, this could take 40 Minutes"
        avi-cli-run --user root --password "${AVE_PASSWORD}" \
        --install upgrade-client-downloads localhost
        echo "Done installing UpgradeClientDownloads"

fi



