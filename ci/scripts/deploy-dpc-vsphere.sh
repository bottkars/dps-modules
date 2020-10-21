#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
DPC_VERSION=$(cat dpc/version)
echo "preparing dpc ${DPC_VERSION} "

govc about
govc import.spec dpc/DPC-${DPC_VERSION}.ova > dpc.json
echo "configuring appliance (vami) settings"

jq  '(.PropertyMapping[] | select(.Key == "vami.ipv4.NetWorker_Virtual_Edition") | .Value) |= env.DPC_ADDRESS' dpc.json > "tmp" && mv "tmp" dpc.json
jq  '(.PropertyMapping[] | select(.Key == "vami.gatewayv4.NetWorker_Virtual_Edition") | .Value) |= env.DPC_GATEWAY' dpc.json > "tmp" && mv "tmp" dpc.json
jq  '(.PropertyMapping[] | select(.Key == "vami.DNS.NetWorker_Virtual_Edition") | .Value) |= env.DPC_DNS' dpc.json  > "tmp" && mv "tmp" dpc.json
jq  '(.PropertyMapping[] | select(.Key == "vami.searchpaths.NetWorker_Virtual_Edition") | .Value) |= env.DPC_SEARCHPATHS' dpc.json  > "tmp" && mv "tmp" dpc.json
jq  '(.PropertyMapping[] | select(.Key == "vami.DPCtimezone.NetWorker_Virtual_Edition") | .Value) |= env.DPC_TIMEZONE' dpc.json  > "tmp" && mv "tmp" dpc.json
jq  '(.PropertyMapping[] | select(.Key == "vami.NTP.NetWorker_Virtual_Edition") | .Value) |= env.DPC_NTP' dpc.json  > "tmp" && mv "tmp" dpc.json
jq  '(.PropertyMapping[] | select(.Key == "vami.vCenterFQDN.NetWorker_Virtual_Edition") | .Value) |= env.GOVC_URL' dpc.json  > "tmp" && mv "tmp" dpc.json
jq  '(.PropertyMapping[] | select(.Key == "vami.vCenterUsername.NetWorker_Virtual_Edition") | .Value) |= env.GOVC_USERNAME' dpc.json  > "tmp" && mv "tmp" dpc.json
jq  '(.PropertyMapping[] | select(.Key == "vami.FQDN.NetWorker_Virtual_Edition") | .Value) |= env.DPC_FQDN' dpc.json  > "tmp" && mv "tmp" dpc.json
jq  '(.NetworkMapping[].Name |= env.DPC_NETWORK)' dpc.json  > "tmp" && mv "tmp" dpc.json
# jq  '(.NetworkMapping[].Network |= "ethernet-0")' dpc.json  > "tmp" && mv "tmp" dpc.json
# jq  '(.PowerOn |= false)' dpc.json  > "tmp" && mv "tmp" dpc.json
jq  '(.InjectOvfEnv |= true)' dpc.json  > "tmp" && mv "tmp" dpc.json

echo "importing dpc ${DPC_VERSION} DPC template"
govc import.ova -name ${DPC_VMNAME} -folder=${DPC_FOLDER}  -options=dpc.json dpc/DPC-${DPC_VERSION}.ova
govc vm.network.change -vm.ipath ${GOVC_VM_IPATH} -net=VLAN250 ethernet-0

govc vm.power -on=true -vm.ipath ${GOVC_VM_IPATH}
echo "finished DELLEMC Networker  ${DPC_VERSION} DPC install"
echo "Waiting for DPC avi-installer to bevome ready, this can take up to 5 Minutes"
until [[ 200 == $(curl -k --write-out "%{http_code}\n" --silent --output /dev/null "https://${DPC_FQDN}:443/avi/avigui.html") ]] ; do
    printf '.'
    sleep 5
done
echo
echo "Appliance https://${DPC_FQDN}:443/avi/avigui.html is ready for Configuration with root:changeme"

