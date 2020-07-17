#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x

echo "installing jq...."
DEBIAN_FRONTEND=noninteractive apt-get install -qq jq < /dev/null > /dev/null
source dps_modules/ci/functions/ppdm_functions.sh
source dps_modules/ci/functions/yaml.sh


create_variables "${PROXY_FILE}" sourced_

echo "evaluated variables from Source Control :"
declare -p | grep 'a sourced_'


printf "evaluating Moref for ${sourced_vsphere_host} ... "
hostMoref=$(govc host.info -json ${sourced_vsphere_host} | jq -r '.HostSystems[0].Self.Value')
echo $hostMoref


printf "evaluating Moref for ${sourced_vsphere_datastore} ... "
dataCenterMoref=$(govc datacenter.info -json ${sourced_vsphere_datacenter}  | jq -r '.Datacenters[].Self.Value')
echo $dataCenterMoref

printf "evaluating Moref for ${sourced_vsphere_folder} ... "
folderMoref=$(govc folder.info -json "${sourced_vsphere_folder}"  | jq -r '.Folders[].Self.Value')
echo $folderMoref

export PPDM_TOKEN=$(get_ppdm_token $PPDM_PASSWORD)
export vmName=$sourced_VMName


assetId=$(get_ppdm_assets  | jq -r 'select(.name == env.vmName).id')
copyId=$(get_ppdm_assets_copies ${assetId} | jq -r .[0].id)
vcenterInventorySourceId=$(get_ppdm_inventory-sources | jq -r 'select(.type=="VCENTER") | select(.address==env.GOVC_URL).id')
request=$(start_ppdm-instant_restored-copies \
    $copyId \
    $vcenterInventorySourceId \
    $vmName \
    $dataCenterMoref \
    $hostMoref )

echo $request | jq -r .




