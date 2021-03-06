#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
DEBIAN_FRONTEND=noninteractive apt-get install -qq jq < /dev/null > /dev/null
AV_BASEURL=$(echo $avamar | jq -r ".BaseURL")
# AV_LOCATION=$(echo $avamar | jq -r ".location")
# AV_RELEASE=$(echo $avamar | jq -r ".release")
AV_VERSION=$(echo $avamar | jq -r ".version")
# ftp://avamar_ftp:anonymous@ftp.emc.com/software/av3494954704/19.2.0.155.vhd.7z
# ftp://avamar_ftp:anonymous@ftp.emc.com/software/av3494954704/19.2.0.155.ova
for PACKAGE in $packages
do
    echo "downloading ${PACKAGE} ${AV_RELEASE}"
    echo "from ${AV_BASEURL}/${AV_LOCATION}/${PACKAGE}-${AV_RELEASE}.${extension}"
    curl --disable-epsv -o ${PACKAGE}/${PACKAGE}-${AV_RELEASE}.${extension} ${AV_BASEURL}/${AV_LOCATION}/${PACKAGE}-${AV_RELEASE}.${extension}
done

