#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation

govc about

if [[ $(govc vm.info ${VPROXY_FOLDER}/${VPROXY_VMNAME}) ]]
then
    echo "VM ${VPROXY_FOLDER}/${VPROXY_VMNAME} already exists, nothing to do here"

else

VPROXY_VERSION=$(cat vproxy/version)
echo "preparing vproxy ${VPROXY_VERSION} VPROXY"


govc import.spec vproxy/vproxy-installer-${VPROXY_VERSION}.ova > vProxy.json








jq  '(.PropertyMapping[] | select(.Key == "vami.DNS.vProxy") | .Value) |= env.VPROXY_DNS' vProxy.json  > "tmp" && mv "tmp" vProxy.json
jq  '(.PropertyMapping[] | select(.Key == "vami.searchDomain.vProxy") | .Value) |= env.VPROXY_SEARCHDOMAIN' vProxy.json > "tmp" && mv "tmp" vProxy.json
jq  '(.PropertyMapping[] | select(.Key == "vami.fqdn.vProxy") | .Value) |= env.VPROXY_FQDN' vProxy.json  > "tmp" && mv "tmp" vProxy.json
jq  '(.PropertyMapping[] | select(.Key == "vami.ip0.vProxy") | .Value) |= env.VPROXY_IP0' vProxy.json > "tmp" && mv "tmp" vProxy.json
jq  '(.PropertyMapping[] | select(.Key == "vami.netmask0.vProxy") | .Value) |= env.VPROXY_NETMASK0' vProxy.json > "tmp" && mv "tmp" vProxy.json
jq  '(.PropertyMapping[] | select(.Key == "vami.gateway.vProxy") | .Value) |= env.VPROXY_GATEWAY' vProxy.json > "tmp" && mv "tmp" vProxy.json
jq  '(.PropertyMapping[] | select(.Key == "vami.fqdn1.vProxy") | .Value) |= env.VPROXY_FQDN1' vProxy.json  > "tmp" && mv "tmp" vProxy.json
jq  '(.PropertyMapping[] | select(.Key == "vami.ip1.vProxy") | .Value) |= env.VPROXY_IP1' vProxy.json > "tmp" && mv "tmp" vProxy.json
jq  '(.PropertyMapping[] | select(.Key == "vami.netmask1.vProxy") | .Value) |= env.VPROXY_NETMASK1' vProxy.json > "tmp" && mv "tmp" vProxy.json
jq  '(.PropertyMapping[] | select(.Key == "vami.gateway1.vProxy") | .Value) |= env.VPROXY_GATEWAY' vProxy.json > "tmp" && mv "tmp" vProxy.json
jq  '(.PropertyMapping[] | select(.Key == "vami.timezone.vProxy") | .Value) |= env.VPROXY_TIMEZONE' vProxy.json  > "tmp" && mv "tmp" vProxy.json
jq  '(.PropertyMapping[] | select(.Key == "vami.NTP.vProxy") | .Value) |= env.VPROXY_NTP' vProxy.json  > "tmp" && mv "tmp" vProxy.json
jq  '(.PropertyMapping[] | select(.Key == "vami.rootpassword.vProxy") | .Value) |= env.VPROXY_ROOT_PASSWORD' vProxy.json  > "tmp" && mv "tmp" vProxy.json
jq  '(.PropertyMapping[] | select(.Key == "vami.adminpassword.vProxy") | .Value) |= env.VPROXY_ADMIN_PASSWORD' vProxy.json  > "tmp" && mv "tmp" vProxy.json

jq  '(.PropertyMapping[] | select(.Key == "vami.FQDN.vProxy") | .Value) |= env.VPROXY_FQDN' vProxy.json  > "tmp" && mv "tmp" vProxy.json
jq  '(.NetworkMapping[0].Name |= env.VPROXY_NETWORK0)' vProxy.json  > "tmp" && mv "tmp" vProxy.json
jq  '(.NetworkMapping[1].Name |= env.VPROXY_NETWORK1)' vProxy.json  > "tmp" && mv "tmp" vProxy.json
jq  '(.NetworkMapping[0].Network |= env.VPROXY_NETWORK0)' vProxy.json  > "tmp" && mv "tmp" vProxy.json
jq  '(.NetworkMapping[1].Network |= env.VPROXY_NETWORK0)' vProxy.json  > "tmp" && mv "tmp" vProxy.json
jq  '(.PowerOn |= false)' vProxy.json  > "tmp" && mv "tmp" vProxy.json
jq  '(.DiskProvisioning |= "thin")' vProxy.json  > "tmp" && mv "tmp" vProxy.json
jq  '(.InjectOvfEnv |= true)' vProxy.json  > "tmp" && mv "tmp" vProxy.json

echo "importing vProxy ${VPROXY_VERSION} template"
govc import.ova -name ${VPROXY_VMNAME} -folder=${VPROXY_FOLDER}  -options=vProxy.json vproxy/vproxy-installer-${VPROXY_VERSION}.ova
govc vm.network.change -vm.ipath ${GOVC_VM_IPATH} -net=${VPROXY_NETWORK0} ethernet-0

govc vm.power -on=true -vm.ipath ${GOVC_VM_IPATH}
echo "finished DELLEMC Networker  ${VPROXY_VERSION} VPROXY install"
echo "Waiting for VPROXY to bevome ready, this can take up to 5 Minutes"
timeout 180 bash -c "</dev/tcp/${VPROXY_FQDN}/22"
echo
echo "VPROXY ${VPROXY_FQDN} is ready for Configuration"

fi
