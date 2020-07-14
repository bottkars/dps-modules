#!/bin/bash
# Function Set for ddve on vsphere

function ddve_env {
  govc guest.getenv -vm $DDVE_VMNAME -l "${DDVE_USERNAME}:${DDVE_PASSWORD}"  
}


function ddsh {
    local command=$@
    local shell=/ddr/bin/ddsh
    govc guest.run -vm.ipath "${GOVC_VM_IPATH}" \
    -l "${DDVE_USERNAME}:${DDVE_PASSWORD}" \
    ${shell} \
    "${command}" 
}    