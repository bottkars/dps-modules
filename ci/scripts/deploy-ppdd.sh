#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
PPDD_VERSION=$(cat ddve/version)
echo "preparing ddve ${PPDD_VERSION} base install"

govc about
if [[ $(govc vm.info -vm.ipath "${GOVC_VM_IPATH}")  ]]
then 
 echo "vm ${GOVC_VM_IPATH} already exists, nothing to do here"
else

govc import.spec ddve/ddve-${PPDD_VERSION}.ova > ddve.json
source dps-modules/ci/functions/govc_functions.sh

echo "configuring appliance (vami) settings for a ${PPDD_TYPE} PowerProtect DD"
jq  '(.DiskProvisioning |= "thin")' ddve.json  > "tmp" && mv "tmp" ddve.json
jq  '(.Deployment |= env.PPDD_TYPE)' ddve.json  > "tmp" && mv "tmp" ddve.json
jq  '(.NetworkMapping[].Name |= env.PPDD_NETWORK)' ddve.json  > "tmp" && mv "tmp" ddve.json

echo "importing ddve ${PPDD_VERSION} template"
govc import.ova -name ${PPDD_VMNAME} -folder=${PPDD_FOLDER} -options=./ddve.json ddve/ddve-${PPDD_VERSION}.ova
govc vm.network.change -vm.ipath ${GOVC_VM_IPATH} -net=VLAN250 ethernet-0
govc vm.change -vm.ipath ${GOVC_VM_IPATH} -m=32768 -mem.reservation=32768

IFS="," read -ra DiskArray <<< "$PPDD_ACTIVETIER_DISKS"
# reads a csv string into array. Note: bash -ra, zsh -rA
# see https://stackoverflow.com/questions/60746331/simplest-way-to-split-a-csv-string-into-an-array-that-works-for-both-bash-zsh
index=0
for DISK in "${DiskArray[@]}"
do
    echo "Creating  disk active_tier${index} with size $DISK"
    create_disk active_tier${index} $DISK
    index=$((index+1))
    # we use set -e, hence index++ would fail !
    # https://stackoverflow.com/questions/7247279/bash-set-e-and-i-0let-i-do-not-agree
done
unset DiskArray
IFS="," read -ra DiskArray <<< "$PPDD_CLOUDTIER_DISKS"
index=0
for DISK in "${DiskArray[@]}"
do
    echo "Creating disk cloud_tier${index} with size $DISK"
    create_disk cloud_tier${index} $DISK
    index=$((index+1))
done

govc vm.power -on=true -vm.ipath ${GOVC_VM_IPATH}
echo "finished DELLEMC PowerProtectDD ${PPDD_VERSION} base install"
fi
echo "Waiting for Appliance IP"
export PPDD_INITIAL_IP=$(govc vm.ip -vm.ipath ${GOVC_VM_IPATH})
echo "Waiting for Appliance Fresh Install to become ready, this can take up to 10 Minutes"
until [[ 301 == $(curl -k --write-out "%{http_code}\n" --silent --output /dev/null "https://${PPDD_INITIAL_IP}:443/ddem") ]] ; do
    printf '.'
    sleep 5
done

echo "Storing initial IP"
echo "DDVE_PUBLIC_FQDN: ${PPDD_INITIAL_IP}" > vars/vars.yml
