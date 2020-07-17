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
HostMoref=$(govc host.info -json ${sourced_vsphere_host} | jq -r '.HostSystems[0].Parent.Value')
echo $hosteMoref


printf "evaluating Moref for ${sourced_vsphere_datastore} ... "
DatastoreMoref=$(govc Datacenters.info -json ${sourced_vsphere_datacenter}  | jq -r '.Datacenters[].Self.Value')
echo $dataCenterMoreof

printf "evaluating Moref for ${sourced_vsphere_folder} ... "
FolderMoref=$(govc folder.info -json ${sourced_vsphere_folder}  | jq -r '.Folders[].Self.Value')
echo $FflderMoref
govc datacenter.info -json home_dc | jq -r '.Datacenters[].Self.Value'




asset_id=$(get_ppdm_assets  | jq -r 'select(.name == env.VMName).id')

copy_id=$(get_ppdm_assets_copies ${asset_id} | jq -r .[0].id)


break
pause




