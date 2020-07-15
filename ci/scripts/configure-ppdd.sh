#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x

echo "installing jq...."
DEBIAN_FRONTEND=noninteractive apt-get install -qq jq < /dev/null > /dev/null
source dps_modules/ci/functions/ddsh_functions.sh
export PPDD_DOMAIN=$(echo $PPDD_FQDN | cut -d'.' -f2-)

ddsh net config ${PPDD_INTERFACE} dhcp no
ddsh net config ${PPDD_INTERFACE} type fixed ${PPDD_ADDRESS} netmask ${PPDD_NETMASK}
ddsh net route add gateway ${PPDD_GATEWAY}
ddsh net set dns ${PPDD_DNS}
ddsh net set hostname ${PPDD_FQDN}
ddsh net set searchdomain  ${PPDD_DOMAIN}
ddsh elicense reset restore-evaluation
ddsh disk rescan
ddsh storage add tier active dev3
ddsh storage add tier cloud dev4
ddsh filesys create
ddsh filesys enable
ddsh ddboost enable
# ddsh cloud enable
ddsh mtree create ${PPDD_NFS_PATH}
ddsh nfs export create path ${PPDD_NFS_PATH} clients ${PPDD_NFS_CLIENT}

