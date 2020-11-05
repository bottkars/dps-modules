#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
source dps-modules/ci/functions/ppdm_functions.sh


if [[ -d ppdm-config ]]
then
    PPDM_CONFIG_VERSION=$(cat ./ppdm-config/version) 
    echo "Found PPDM confiog file, evaluating Variables from vonfiguration Version ${PPDM_CONFIG_VERSION}"
    eval "$(jq -r 'keys[] as $key | "export \($key)=\"\(.[$key].value)\""' ./ppdm-config/tf-output-${PPDM_CONFIG_VERSION}.json)"
    export INVENTORY_FQDN="https://${DDVE_FQDN}"
fi

echo "requesting API token"


export PPDM_TOKEN=$(get_ppdm_token ${PPDM_PASSWORD})

echo "Creating INVENTORY Credentials for ${INVENTORY_USERNAME}"
CREDENTIALS=$(create_ppdm_credentials  ${INVENTORY_CREDENTIAL_TYPE} ${INVENTORY_USERNAME} ${INVENTORY_PASSWORD})
CREDENTIALS_ID=$(echo $CREDENTIALS | jq -r '.id')



echo "Trusting INVENTORY ${INVENTORY_FQDN} certificate"
# lazy retry timer until we got it .......
until ( [[ ! -z $(get_ppdm_certificates | jq -r '.content[] | select(.host==env.INVENTORY_FQDN) | select(.state=="ACCEPTED")') ]] )  
#     [[ ! -z $(trust_ppdm_host_certificate "${CERTIFICATE}" "${CERT_ID}" | jq -r '. | select(.state=="ACCEPTED")') ]]  )
    do
        CERTIFICATE=$(get_ppdm_host_certificate  "${INVENTORY_FQDN}" ${INVENTORY_PORT})
        CERTIFICATE=$(echo $CERTIFICATE | jq -r '.[]' )
        CERTIFICATE=$(echo $CERTIFICATE | jq '(.state |= "ACCEPTED")' )
        CERT_ID=$(echo $CERTIFICATE | jq -r '.id')
        trust_ppdm_host_certificate "${CERTIFICATE}" "${CERT_ID}"
        sleep 5
        printf "."
    done
echo

echo "Adding INVENTORY ${INVENTORY_FQDN} to inventory"
INVENTORY_NAME=$(echo ${INVENTORY_FQDN} | cut -d '.' -f-1  )
create_ppdm_inventory-source $INVENTORY_TYPE ${INVENTORY_NAME} "${INVENTORY_FQDN}" $CREDENTIALS_ID ${INVENTORY_PORT}