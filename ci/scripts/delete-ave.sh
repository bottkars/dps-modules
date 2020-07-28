#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
govc about
govc vm.info ${NVE_VMNAME}
echo "deleting PowerProtect Appliance ${NVE_VMNAME}"
govc vm.destroy ${NVE_VMNAME}
echo "done"
