#!/usr/bin/env bash
set -e
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
govc about
source dps-modules/ci/functions/avamar_rest_client.sh

until [[ AVAMAR_TOKEN=$(get_avamar_token $AVE_PASSWORD) ]]
do
sleep 5
done


echo "Reading Proxies from ${AVAMAR_FQDN}"
PROXIES=$(get_avamar_proxies | jq .content)
echo "Reading vCenters from ${AVAMAR_FQDN}"
VCENTERS=$(get_avamar_virtualcenters)
export length=$(echo $PROXIES | jq '. | length') 

### we will build the loop once single proxy works
if [[ "$length" -gt 0 ]]
then
PROXY=$(echo $PROXIES | jq '.[(env.length|tonumber)-1]')
ID=$(echo $PROXY | jq -r '.id')
UUID=$(echo $PROXY | jq -r '.biosUuid')  
VCENTER_ID=$(echo $VCENTERS | jq -r  '. | select(.name==env.VCENTER_NAME).cid')
PROXY_FQDN=$(echo $PROXY | jq -r .name)
echo "getting instance UUID for ${PROXY_FQDN} with ${UUID} from vCenter"
INSTANCE_UUID=$(govc vm.info -vm.uuid ${UUID} --json | jq -r '.VirtualMachines[].Config.InstanceUuid')

echo "Getting current proxy recommendation"
RECOMMEND=$(get_avamar_virtualcenters_proxies_recommend ${VCENTER_ID} ${DATACENTER_NAME})

update_avamar_proxies $VCENTER_ID $INSTANCE_UUID

else
    echo "No Proxies found or registered"
    exit 1
fi

