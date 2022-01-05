#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
# DEBIAN_FRONTEND=noninteractive apt-get install -qq jq < /dev/null > /dev/null
source dps-modules/ci/functions/ppdm_functions.sh
source dps-modules/ci/functions/yaml.sh


export REF_VERSION=$(cat ./variable/version)
FILE=${PROXY_FILE}${REF_VERSION}.yml
echo "Using $PROXY_FILE versioned ${REF_VERSION}"
create_variables "${FILE}" sourced_

echo "evaluated variables from Source Control :"
declare -p | grep 'a sourced_'


printf "evaluating Moref for ${sourced_vsphere_host} ... "
hostMoref=$(govc host.info -json ${sourced_vsphere_host} | jq -r '.HostSystems[0].Self.Value')
echo $hostMoref


printf "evaluating Moref for ${sourced_vsphere_datacenter} ... "
dataCenterMoref=$(govc datacenter.info -json ${sourced_vsphere_datacenter}  | jq -r '.Datacenters[].Self.Value')
echo $dataCenterMoref

printf "evaluating Moref for ${sourced_vsphere_folder} ... "
folderMoref=$(govc folder.info -json "${sourced_vsphere_folder}"  | jq -r '.Folders[].Self.Value')
echo $folderMoref

export PPDM_TOKEN=$(get_ppdm_token $PPDM_PASSWORD)
export vmName=$sourced_VMName


assetId=$(get_ppdm_assets  | jq -r 'select(.name == env.vmName).id')
echo "==>using Asset ID ${assetId}"
copyId=$(get_ppdm_assets_copies ${assetId} | jq -r .[0].id)
echo "==>using Copy ID ${copyId}"

vcenterInventorySourceId=$(get_ppdm_inventory-sources | jq -r 'select(.type=="VCENTER") | select(.address==env.GOVC_URL).id')

echo "==> Trigger job for instant access of ${vmName} as ${vmName}-${REF_VERSION}"

request=$(start_ppdm-instant_restored-copies \
    $copyId \
    $vcenterInventorySourceId \
    $vmName \
    $dataCenterMoref \
    $hostMoref \
    $folderMoref \
    $REF_VERSION \
    )



echo $request | jq -r .
export timestamp="$(date '+%Y%m%d.%-H%M.%S')"

INSTANT_FILE="$(echo "$INSTANT_FILE" | envsubst)" 
echo $request | jq -r . >> instant_access/${INSTANT_FILE}






