#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
govc about
govc vm.info ${VMNAME}
echo "deleting VM ${VMNAME}"
govc vm.destroy ${VMNAME}
echo "done"
