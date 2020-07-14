#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x

echo "installing jq...."
DEBIAN_FRONTEND=noninteractive apt-get install -qq jq < /dev/null > /dev/null



source dps_modules/ci/functions/ddsh_functions.sh



export DDVE_DOMAIN=$(echo $DDVE_FQDN | cut -d'.' -f2-)
ddsh net config ${DDVE_INTERFACE} dhcp no
ddsh net config ${DDVE_INTERFACE} type fixed ${DDVE_ADDRESS} netmask ${DDVE_NETMASK}
ddsh net route add gateway ${DDVE_GATEWAY}
ddsh net set dns ${DDVE_DNS}
ddsh net set hostname ${DDVE_FQDN}
ddsh net set searchdomain  ${DDVE_DOMAIN}
ddsh elicense reset restore-evaluation
ddsh disk rescan
ddsh storage add tier active dev3
ddsh storage add tier cloud dev4
ddsh filesys create
ddsh filesys enable
ddsh ddboost enable
# ddsh cloud enable
ddsh mtree create ${DDVE_NFS_PATH}
ddsh nfs export create path ${DDVE_NFS_PATH} clients ${DDVE_NFS_CLIENT}

