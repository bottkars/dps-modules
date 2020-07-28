#!/bin/bash
# general govc functions for ease of use
function create_disk {
    local disk_name=${1}
    local disk_size=${2}
    local vm_name=$(echo $GOVC_VM_IPATH | rev |cut -d '/' -f1 | rev)
    govc vm.disk.create -vm.ipath "${GOVC_VM_IPATH}" \
-name "$vm_name/${disk_name}" -size ${disk_size}
}