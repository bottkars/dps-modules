#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
govc about
govc vm.info ${PPDD_VMNAME}
echo "deleting PowerProtect Appliance ${PPDD_VMNAME}"
govc vm.destroy ${PPDD_VMNAME}
echo "done"
