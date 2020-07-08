#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x


echo "installing jq...."
DEBIAN_FRONTEND=noninteractive apt-get install -qq jq < /dev/null > /dev/null
source dps_modules/ci/functions/ppdm_functions.sh
echo "requesting API token"


TOKEN=$(get_ppdm_token ${PPDM_PASSWORD})

echo "Creating INVENTORY Credentials for ${INVENTORY_USERNAME}"
CREDENTIALS=$(create_ppdm_credentials ${TOKEN} ${INVENTORY_CREDENTIAL_TYPE} ${INVENTORY_USERNAME} ${INVENTORY_PASSWORD})
CREDENTIALS_ID=$(echo $CREDENTIALS | jq -r '.id')

CERTIFICATE=$(get_ppdm_host_certificate $TOKEN "${INVENTORY_FQDN}" ${INVENTORY_PORT})
CERTIFICATE=$(echo $CERTIFICATE | jq -r '.[]' )
CERTIFICATE=$(echo $CERTIFICATE | jq '(.state |= "ACCEPTED")' )
CERT_ID=$(echo $CERTIFICATE | jq -r '.id')

echo "Trusting INVENTORY ${INVENTORY_FQDN} certificate $CERTIFICATE"
trust_ppdm_host_certificate "${TOKEN}" "${CERTIFICATE}" "${CERT_ID}"

echo "Adding INVENTORY ${INVENTORY_FQDN} to inventory"
INVENTORY_NAME=$(echo ${INVENTORY_FQDN} | cut -d '.' -f-1  )
create_ppdm_inventory_source $TOKEN $INVENTORY_TYPE ${INVENTORY_NAME} "${INVENTORY_FQDN}" $CREDENTIALS_ID ${INVENTORY_PORT}
