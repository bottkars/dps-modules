#!/bin/bash
# Function Set for ddve on vsphere


function avi-cli {
    local command=$@
    local shell="/bin/bash -I -c"
    govc guest.run -vm.ipath "${GOVC_VM_IPATH}" \
    -l "${AVE_USERNAME}:${AVE_PASSWORD}" \
    ${shell} \
    "\"source /etc/profile.local; avi-cli ${command}\"" 
}    


NVE_PACKAGE=$(echo $(govc guest.run -l=admin:changeme \
-vm.ipath ${GOVC_VM_IPATH} \
 /opt/emc-tools/bin/avi-cli --user root --password "changeme" \
 --listbycategory 'SW\ Releases' localhost 2> /dev/null ) \
 | grep aveconfig | awk  '{print $8}')
sleep 5
printf "."
done