#!/bin/bash
function create_disk {
    local disk_name=${1}
    local disk_size=${2}
    govc vm.disk.create -vm.ipath "${GOVC_VM_IPATH}" \
-name "$PPDD_VMNAME/${disk_name}" -size ${disk_size}
}