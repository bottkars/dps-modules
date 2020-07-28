#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
AVE_VERSION=$(cat avamar/version)
echo "preparing avamar ${AVE_VERSION} nve"

govc about

echo "checking for jq...."
DEBIAN_FRONTEND=noninteractive apt-get install -qq jq < /dev/null > /dev/null
govc import.spec avamar/AVE-${AVE_VERSION}.ova > avamar.json
echo "configuring appliance (vami) settings"

break 1

sleep 10000

jq  '(.PropertyMapping[] | select(.Key == "vami.ipv4.NetWorker_Virtual_Edition") | .Value) |= env.AVE_ADDRESS' avamar.json > "tmp" && mv "tmp" avamar.json
jq  '(.PropertyMapping[] | select(.Key == "vami.gatewayv4.NetWorker_Virtual_Edition") | .Value) |= env.AVE_GATEWAY' avamar.json > "tmp" && mv "tmp" avamar.json
jq  '(.PropertyMapping[] | select(.Key == "vami.DNS.NetWorker_Virtual_Edition") | .Value) |= env.AVE_DNS' avamar.json  > "tmp" && mv "tmp" avamar.json
jq  '(.PropertyMapping[] | select(.Key == "vami.searchpaths.NetWorker_Virtual_Edition") | .Value) |= env.AVE_SEARCHPATHS' avamar.json  > "tmp" && mv "tmp" avamar.json
jq  '(.PropertyMapping[] | select(.Key == "vami.AVEtimezone.NetWorker_Virtual_Edition") | .Value) |= env.AVE_TIMEZONE' avamar.json  > "tmp" && mv "tmp" avamar.json
jq  '(.PropertyMapping[] | select(.Key == "vami.NTP.NetWorker_Virtual_Edition") | .Value) |= env.AVE_NTP' avamar.json  > "tmp" && mv "tmp" avamar.json
jq  '(.PropertyMapping[] | select(.Key == "vami.vCenterFQDN.NetWorker_Virtual_Edition") | .Value) |= env.GOVC_URL' avamar.json  > "tmp" && mv "tmp" avamar.json
jq  '(.PropertyMapping[] | select(.Key == "vami.vCenterUsername.NetWorker_Virtual_Edition") | .Value) |= env.GOVC_USERNAME' avamar.json  > "tmp" && mv "tmp" avamar.json
jq  '(.PropertyMapping[] | select(.Key == "vami.FQDN.NetWorker_Virtual_Edition") | .Value) |= env.AVE_FQDN' avamar.json  > "tmp" && mv "tmp" avamar.json
jq  '(.NetworkMapping[].Name |= env.AVE_NETWORK)' avamar.json  > "tmp" && mv "tmp" avamar.json
# jq  '(.NetworkMapping[].Network |= "ethernet-0")' avamar.json  > "tmp" && mv "tmp" avamar.json
# jq  '(.PowerOn |= false)' avamar.json  > "tmp" && mv "tmp" avamar.json
jq  '(.InjectOvfEnv |= true)' avamar.json  > "tmp" && mv "tmp" avamar.json

echo "importing avamar ${AVE_VERSION} AVE template"
govc import.ova -name ${AVE_VMNAME} -folder=${AVE_FOLDER}  -options=avamar.json avamar/AVE-${AVE_VERSION}.ova
govc vm.network.change -vm.ipath ${GOVC_VM_IPATH} -net=VLAN250 ethernet-0

govc vm.power -on=true -vm.ipath ${GOVC_VM_IPATH}
echo "finished DELLEMC Networker  ${AVE_VERSION} AVE install"
echo "Waiting for AVE avi-installer to bevome ready, this can take up to 5 Minutes"
until [[ 200 == $(curl -k --write-out "%{http_code}\n" --silent --output /dev/null "https://${AVE_FQDN}:443/avi/avigui.html") ]] ; do
    printf '.'
    sleep 5
done
echo
echo "Appliance https://${AVE_FQDN}:443/avi/avigui.html is ready for Configuration with root:changeme"

