#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
AVE_VERSION=$(cat avamar/version)
govc about
echo "preparing avamar ${AVE_VERSION} Virtual Edition for ${AVE_VMNAME}"


govc import.spec avamar/AVE-${AVE_VERSION}.ova > avamar.json
echo "configuring appliance (vami) settings"
source dps-modules/ci/functions/govc_functions.sh

echo "Configuring OVS Settings"

jq  '(.DiskProvisioning |= "thin")' avamar.json  > "tmp" && mv "tmp" avamar.json

jq  '(.PropertyMapping[] | select(.Key == "vami.ipv4.Avamar_Virtual_Edition") | .Value) |= env.AVE_ADDRESS' avamar.json > "tmp" && mv "tmp" avamar.json
jq  '(.PropertyMapping[] | select(.Key == "vami.gatewayv4.Avamar_Virtual_Edition") | .Value) |= env.AVE_GATEWAY' avamar.json > "tmp" && mv "tmp" avamar.json
jq  '(.PropertyMapping[] | select(.Key == "vami.DNS.Avamar_Virtual_Edition") | .Value) |= env.AVE_DNS' avamar.json  > "tmp" && mv "tmp" avamar.json
jq  '(.PropertyMapping[] | select(.Key == "vami.searchpaths.Avamar_Virtual_Edition") | .Value) |= env.AVE_SEARCHPATHS' avamar.json  > "tmp" && mv "tmp" avamar.json
jq  '(.PropertyMapping[] | select(.Key == "vami.AVEtimezone.Avamar_Virtual_Edition") | .Value) |= env.AVE_TIMEZONE' avamar.json  > "tmp" && mv "tmp" avamar.json
jq  '(.PropertyMapping[] | select(.Key == "vami.NTP.Avamar_Virtual_Edition") | .Value) |= env.AVE_NTP' avamar.json  > "tmp" && mv "tmp" avamar.json
# jq  '(.PropertyMapping[] | select(.Key == "vami.vCenterFQDN.Avamar_Virtual_Edition") | .Value) |= env.GOVC_URL' avamar.json  > "tmp" && mv "tmp" avamar.json
# jq  '(.PropertyMapping[] | select(.Key == "vami.vCenterUsername.Avamar_Virtual_Edition") | .Value) |= env.GOVC_USERNAME' avamar.json  > "tmp" && mv "tmp" avamar.json
jq  '(.PropertyMapping[] | select(.Key == "vami.FQDN.Avamar_Virtual_Edition") | .Value) |= env.AVE_FQDN' avamar.json  > "tmp" && mv "tmp" avamar.json
jq  '(.NetworkMapping[].Name |= env.AVE_NETWORK)' avamar.json  > "tmp" && mv "tmp" avamar.json
# jq  '(.NetworkMapping[].Network |= "ethernet-0")' avamar.json  > "tmp" && mv "tmp" avamar.json
# jq  '(.PowerOn |= false)' avamar.json  > "tmp" && mv "tmp" avamar.json
jq  '(.InjectOvfEnv |= true)' avamar.json  > "tmp" && mv "tmp" avamar.json

echo "importing avamar ${AVE_VERSION} AVE template as VM ${AVE_VMNAME}"
govc import.ova -name ${AVE_VMNAME} -folder=${AVE_FOLDER}  -options=avamar.json avamar/AVE-${AVE_VERSION}.ova
govc vm.network.change -vm.ipath ${GOVC_VM_IPATH} -net=VLAN250 ethernet-0


case "${AVE_SIZE}" in
    "0.5TB")       
    AVE_CPU=2
    AVE_MEM=6144
    AVE_DISK_SIZE=250G
    AVE_DISK_COUNT=3
    ;;
    "1TB")
    AVE_CPU=2
    AVE_MEM=8192
    AVE_DISK_SIZE=250G
    AVE_DISK_COUNT=6
    ;;            
    "2TB")
    AVE_CPU=2
    AVE_MEM=16384
    AVE_DISK_SIZE=1000G
    AVE_DISK_COUNT=3
    ;;
    "4TB")
    AVE_CPU=4
    AVE_MEM=36864
    AVE_DISK_SIZE=1000G
    AVE_DISK_COUNT=6
    ;;  
    "8TB")
    AVE_CPU=8
    AVE_MEM=49125
    AVE_DISK_SIZE=1000G
    AVE_DISK_COUNT=12
    ;;  
    "16TB")
    AVE_CPU=16
    AVE_MEM=99304
    AVE_DISK_SIZE=2000G
    AVE_DISK_COUNT=12
    ;;  
    *)
    break
esac 

echo "Setting AVE ${AVE_VMNAME} to  
    ${AVE_CPU} CPU
    ${AVE_MEM}MB Memory
    ${AVE_DISK_SIZE}B Disk Size
    ${AVE_DISK_COUNT} Disk Count
    "

govc vm.change -vm.ipath ${GOVC_VM_IPATH} -m=${AVE_MEM} -mem.reservation=1024
# looping the disk creation
i=1
until [ $i -gt $AVE_DISK_COUNT ]; do
   echo "Creating disk${i} with ${AVE_DISK_SIZE}B"
   create_disk "gsandisk${i}" "${AVE_DISK_SIZE}"
   let i++
done


govc vm.power -on=true -vm.ipath ${GOVC_VM_IPATH}
echo "finished DELLEMC Avamar ${AVE_VERSION} Virtual Edition install for ${AVE_VMNAME}"

