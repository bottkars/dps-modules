#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x

govc about
govc vm.info ${PPDM_VMNAME}
echo "deleting PowerProtect Appliance ${PPDM_VMNAME}"
govc vm.destroy ${PPDM_VMNAME}
echo "done"
