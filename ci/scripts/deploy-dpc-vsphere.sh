#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
DPC_VERSION=$(cat dpc/version)
echo "preparing dpc ${DPC_VERSION}"

govc about
govc import.spec dpc/emc-dpc-ova-${DPC_VERSION}.ova > brs.json
echo "configuring appliance (vami) settings"

    echo "configuring appliance (vami) settings"
    jq  '(.PropertyMapping[] | select(.Key == "vami.ip0.brs") | .Value) |= env.DPC_ADDRESS' brs.json > "tmp" && mv "tmp" brs.json
    jq  '(.PropertyMapping[] | select(.Key == "vami.gateway.brs") | .Value) |= env.DPC_GATEWAY' brs.json > "tmp" && mv "tmp" brs.json
    jq  '(.PropertyMapping[] | select(.Key == "vami.netmask0.brs") | .Value) |= env.DPC_NETMASK' brs.json  > "tmp" && mv "tmp" brs.json
    jq  '(.PropertyMapping[] | select(.Key == "vami.DNS.brs") | .Value) |= env.DPC_DNS' brs.json  > "tmp" && mv "tmp" brs.json
    jq  '(.PropertyMapping[] | select(.Key == "vami.fqdn.brs") | .Value) |= env.DPC_FQDN' brs.json  > "tmp" && mv "tmp" brs.json
    jq  '(.PropertyMapping[] | select(.Key == "vami.NTP.brs") | .Value) |= env.DPC_NTP' brs.json  > "tmp" && mv "tmp" brs.json
    jq  '(.PropertyMapping[] | select(.Key == "vami.root-password.brs") | .Value) |= env.DPC_ROOT_PASSWORD' brs.json  > "tmp" && mv "tmp" brs.json
    jq  '(.PropertyMapping[] | select(.Key == "vami.admin-password.brs") | .Value) |= env.DPC_ADMIN_PASSWORD' brs.json  > "tmp" && mv "tmp" brs.json
    jq  '(.PropertyMapping[] | select(.Key == "vami.ui-password.brs") | .Value) |= env.DPC_UI_PASSWORD' brs.json  > "tmp" && mv "tmp" brs.json
    jq  '(.PropertyMapping[] | select(.Key == "vami.lockbox-password.brs") | .Value) |= env.DPC_LOCKBOX_PASSWORD' brs.json  > "tmp" && mv "tmp" brs.json
    jq  '(.PropertyMapping[] | select(.Key == "vami.timezone.brs") | .Value) |= env.DPC_TIMEZONE' brs.json  > "tmp" && mv "tmp" brs.json



    jq  '(.DiskProvisioning |= "thin")' brs.json  > "tmp" && mv "tmp" brs.json
    jq  '(.NetworkMapping[].Name |= env.DPC_NETWORK)' brs.json  > "tmp" && mv "tmp" brs.json
    echo "importing dpc ${DPC_VERSION} template"
    govc import.ova -name ${DPC_VMNAME} -folder=${DPC_FOLDER} -options=brs.json dpc/emc-dpc-ova--${DPC_VERSION}.ova
    govc vm.network.change -vm.ipath ${GOVC_VM_IPATH} -net=VLAN250 ethernet-0

    govc vm.power -on=true -vm.ipath ${GOVC_VM_IPATH}
    echo "finished DELLEMC PowerProtect ${DPC_VERSION} base install"
    echo "Waiting for Appliance Fresh Install to become ready, this can take up to 10 Minutes"
    until [[ 200 == $(curl -k --write-out "%{http_code}\n" --silent --output /dev/null "https://${DPC_FQDN}:443/#/fresh") ]] ; do
        printf '.'
        sleep 5
    done
    echo
    echo "Appliance https://${DPC_FQDN}:8443/api/v2 ready for Configuration"
fi

