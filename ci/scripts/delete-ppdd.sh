#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x

govc about
govc vm.info ${DDVE_VMNAME}
echo "deleting PowerProtect Appliance ${DDVE_VMNAME}"
govc vm.destroy ${DDVE_VMNAME}
echo "done"
