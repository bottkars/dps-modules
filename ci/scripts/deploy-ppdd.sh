#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
DDVE_VERSION=$(cat ddve/version)
echo "preparing ddve ${DDVE_VERSION} base install"

govc about

echo "installing jq...."
DEBIAN_FRONTEND=noninteractive apt-get install -qq jq < /dev/null > /dev/null
govc import.spec ddve/ddve-${DDVE_VERSION}.ova > ddve.json
source dps_modules/ci/functions/govc_functions.sh

echo "configuring appliance (vami) settings for a ${DDVE_TYPE} PowerProtect DDVE"
jq  '(.DiskProvisioning |= "thin")' ddve.json  > "tmp" && mv "tmp" ddve.json
jq  '(.Deployment |= env.DDVE_TYPE)' ddve.json  > "tmp" && mv "tmp" ddve.json
jq  '(.NetworkMapping[].Name |= env.DDVE_NETWORK)' ddve.json  > "tmp" && mv "tmp" ddve.json

echo "importing ddve ${DDVE_VERSION} template"
govc import.ova -name ${DDVE_VMNAME} -folder=${DDVE_FOLDER} -options=./ddve.json ddve/ddve-${DDVE_VERSION}.ova
govc vm.network.change -vm.ipath ${GOVC_VM_IPATH} -net=VLAN250 ethernet-0
govc vm.change -vm.ipath ${GOVC_VM_IPATH} -m=32768 -mem.reservation=32768
create_disk local_tier 200G
create_disk cloud_tier 1T
govc vm.power -on=true -vm.ipath ${GOVC_VM_IPATH}
echo "finished DELLEMC PowerProtectDD ${DDVE_VERSION} base install"
export DDVE_ININTIAL_IP=$(govc vm.ip -vm.ipath ${GOVC_VM_IPATH})
echo "Waiting for Appliance Fresh Install to become ready, this can take up to 10 Minutes"
until [[ 301 == $(curl -k --write-out "%{http_code}\n" --silent --output /dev/null "https://${DDVE_ININTIAL_IP}:443/ddem") ]] ; do
    printf '.'
    sleep 5
done
