#!/bin/bash
# Function Set for ddve on vsphere

function ddve_env {
  govc guest.getenv -vm $PPDD_VMNAME -l "${PPDD_USERNAME}:${PPDD_PASSWORD}"  
}


function ddsh {
    local command=$@
    local shell=/ddr/bin/ddsh
    govc guest.run -vm.ipath "${GOVC_VM_IPATH}" \
    -l "${PPDD_USERNAME}:${PPDD_PASSWORD}" \
    ${shell} \
    "${command}" 
}    