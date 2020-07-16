#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x

echo "installing jq...."
DEBIAN_FRONTEND=noninteractive apt-get install -qq jq < /dev/null > /dev/null
source dps_modules/ci/functions/ppdm_functions.sh
source dps_modules/ci/functions/yaml.sh

create_variables "${PROXY_FILE}"
export PPDM_TOKEN=$(get_ppdm_token $PPDM_PASSWORD)
printf "evaluating Moref for ${vsphere_host} ... "
ClusterMoref=$(govc host.info -json ${vsphere_host} | jq -r '.HostSystems[0].Parent.Value')
echo $ClusterMoref
printf "evaluating Moref for ${vsphere_portgroup} ${vsphere_vswitch} ... "
NetworkMoref=$(govc dvs.portgroup.info -json -pg ${vsphere_portgroup} ${vsphere_vswitch} | jq -r '.Port[0].PortgroupKey')
echo $NetworkMoref
printf "evaluating Moref for ${vsphere_datastore} ... "
DatastoreMoref=$(govc datastore.info -json ${vsphere_datastore}  | jq -r '.Datastores[].Self.Value')
echo $DatastoreMoref

protection_engine_id=$(get_ppdm_protection-engines | jq -r .id)
VimServerRefID=$(get_ppdm_inventory-sources  | jq -r 'select(.address==env.GOVC_URL) | .id')

add_ppdm_protection_engine_proxy  \
    "${protection_engine_id}" \
    "${NetworkMoref}" \
    "${ClusterMoref}" \
    "${DatastoreMoref}" \
    "${Fqdn}" \
    "${IpAddress}" \
    "${NetMask}" \
    "${Gateway}" \
    "${Dns}" \
    "${IPProtocol}" \
    "${HostName}" \
    "${VimServerRefID}"