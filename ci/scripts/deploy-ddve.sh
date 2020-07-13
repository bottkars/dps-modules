#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
DDVE_VERSION=$(cat ddve/version)
echo "preparing ddve ${DDVE_VERSION} base install"

govc about

echo "installing jq...."
DEBIAN_FRONTEND=noninteractive apt-get install -qq jq < /dev/null > /dev/null
govc import.spec ddve/ddve-${DDVE_VERSION}.ova > ddve.json
break
echo "configuring appliance (vami) settings"
jq  '(.PropertyMapping[] | select(.Key == "vami.ip0.brs") | .Value) |= env.DDVE_ADDRESS' ddve.json > "tmp" && mv "tmp" ddve.json
jq  '(.PropertyMapping[] | select(.Key == "vami.gateway.brs") | .Value) |= env.DDVE_GATEWAY' ddve.json > "tmp" && mv "tmp" ddve.json
jq  '(.PropertyMapping[] | select(.Key == "vami.netmask0.brs") | .Value) |= env.DDVE_NETMASK' ddve.json  > "tmp" && mv "tmp" ddve.json
jq  '(.PropertyMapping[] | select(.Key == "vami.DNS.brs") | .Value) |= env.DDVE_DNS' ddve.json  > "tmp" && mv "tmp" ddve.json
jq  '(.PropertyMapping[] | select(.Key == "vami.fqdn.brs") | .Value) |= env.DDVE_FQDN' ddve.json  > "tmp" && mv "tmp" ddve.json
jq  '(.DiskProvisioning |= "thin")' ddve.json  > "tmp" && mv "tmp" ddve.json
jq  '(.NetworkMapping[].Name |= env.DDVE_NETWORK)' ddve.json  > "tmp" && mv "tmp" ddve.json
echo "importing ddve ${DDVE_VERSION} template"
govc import.ova -name ${DDVE_VMNAME}  -options=ddve.json ddve/dellemc-ppdm-sw-${DDVE_VERSION}.ova
govc vm.network.change -vm ${DDVE_VMNAME} -net=VLAN250 ethernet-0

govc vm.power -on=true ${DDVE_VMNAME}
echo "finished DELLEMC PowerProtect ${DDVE_VERSION} base install"
echo "Waiting for Appliance Fresh Install to become ready, this can take up to 10 Minutes"
until [[ 200 == $(curl -k --write-out "%{http_code}\n" --silent --output /dev/null "https://${DDVE_FQDN}:443/#/fresh") ]] ; do
    printf '.'
    sleep 5
done
echo
echo "Appliance https://${DDVE_FQDN}:8443/api/v2 ready for Configuration"

