#!/bin/bash
# Function Set for ddve on vsphere


function avi-cli-run {
    local command=$@
    local shell="/bin/bash -c"
    govc guest.run -vm.ipath "${GOVC_VM_IPATH}" \
    -l "${AVE_USERNAME}:${AVE_PASSWORD}" \
    ${shell} \
    "\"source /etc/profile.local; avi-cli ${command}\"" 
}    

function avi-cli-start {
    local command=$@
    local shell="/bin/bash -c"
    govc guest.start -vm.ipath "${GOVC_VM_IPATH}" \
    -l "${AVE_USERNAME}:${AVE_PASSWORD}" \
    ${shell} \
    "\"source /etc/profile.local; avi-cli ${command}\"" 
} 