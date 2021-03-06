#!/bin/bash
set -eu
if [[ "${DEBUG}" == "TRUE" ]]
    then set -x
    export PLAYBOOK="${PLAYBOOK} -vvv"
fi
figlet DPS Automation
source dps-modules/ci/functions/ppdm_functions.sh
source dps-modules/ci/functions/yaml.sh

create_variables "${PROXY_FILE}" sourced_

echo "evaluated variables from Source Control :"
declare -p | grep 'a sourced_'


printf "evaluating Moref for ${sourced_vsphere_host} ... "
ClusterMoref=$(govc host.info -json ${sourced_vsphere_host} | jq -r '.HostSystems[0].Parent.Value')
echo $ClusterMoref

printf "evaluating Moref for ${sourced_vsphere_portgroup} ${sourced_vsphere_vswitch} ... "
NetworkMoref=$(govc dvs.portgroup.info -json -pg ${sourced_vsphere_portgroup} ${sourced_vsphere_vswitch} | jq -r '.Port[0].PortgroupKey')
echo $NetworkMoref

printf "evaluating Moref for ${sourced_vsphere_datastore} ... "
DatastoreMoref=$(govc datastore.info -json ${sourced_vsphere_datastore}  | jq -r '.Datastores[].Self.Value')
echo $DatastoreMoref

printf "evaluating Moref for ${sourced_vsphere_folder} ... "
FolderMoref=$(govc folder.info -json ${sourced_vsphere_folder}  | jq -r '.Folders[].Self.Value')
echo $FolderMoref


echo "Getting Access Token"
export PPDM_TOKEN=$(get_ppdm_token "${PPDM_PASSWORD}")

echo "Getting Protection Engine"


protection_engine_id=$(get_ppdm_protection-engines | jq -r '.id' )
echo "Getting VimServerRefID"
VimServerRefID=$(get_ppdm_inventory-sources  | jq -r 'select(.address==env.GOVC_URL) | .id')
echo "Requesting new Engine"
request=$(add_ppdm_protection_engine_proxy \
    "${protection_engine_id}" \
    "${NetworkMoref}" \
    "${ClusterMoref}" \
    "${DatastoreMoref}" \
    "${FolderMoref}" \
    "${sourced_Fqdn}" \
    "${sourced_IpAddress}" \
    "${sourced_NetMask}" \
    "${sourced_Gateway}" \
    "${sourced_Dns}" \
    "${sourced_IPProtocol}" \
    "${sourced_VMName}" \
    "${VimServerRefID}" \
    )
echo $request | jq -r .