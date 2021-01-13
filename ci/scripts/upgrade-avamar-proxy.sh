#!/usr/bin/env bash
set -e
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation

source dps-modules/ci/functions/avamar_rest_client.sh

AVAMAR_TOKEN=$(get_avamar_token $AVE_PASSWORD)

PROXIES=$(get_avamar_proxies)
export length=$(echo $PROXIES | jq '. | length') 
govc about



### we will build the loop once single proxy works
if [[ "$length" -gt 0 ]]
then
PROXY=$(echo $PROXIES | jq '.[(env.length|tonumber)-1]')
ID=$(echo $PROXY | jq -r '.id')
UUID=$(echo $PROXY | jq -r '.biosUuid')
VCENTER_ID=$(echo $VCENTERS | jq -r  '. | select(.name==env.VCENTER_NAME).cid')

PROXY_FQDN=$(echo $PROXY | jq -r .name)

echo "getting instance UUID from vCenter"
INSTANCE_UUID=$(govc vm.info -vm.dns ${PROXY_FQDN} --json | jq -r '.VirtualMachines[].Config.InstanceUuid')

echo "Getting current proxy recommendation"
RECOMMEND=$(get_avamar_virtualcenters_proxies_recommend ${VCENTER_ID} ${DATACENTER_NAME})

update_avamar_proxies $VCENTER_ID $INSTANCE_UUID

fi

