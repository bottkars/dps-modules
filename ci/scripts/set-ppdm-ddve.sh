#!/bin/bash
set -eu

echo "installing jq...."
DEBIAN_FRONTEND=noninteractive apt-get install -qq jq < /dev/null > /dev/null
source dps_modules/ci/functions/ppdm_functions.sh
echo "requesting API token"


TOKEN=$(get_ppdm_token ${PPDM_PASSWORD})

echo "Creating DDVE Credentials for ${DDVE_USERNAME}"
CREDENTIALS=$(create_ppdm_credentials ${TOKEN} DATADOMAIN ${DDVE_USERNAME} ${DDVE_PASSWORD})
CREDENTIALS_ID=$(echo $CREDENTIALS | jq -r '.id')

CERTIFICATE=$(get_ppdm_host_certificate $TOKEN $DDVE_FQDN)
CERTIFICATE=$(echo $CERTIFICATE | jq -r '.[]' )
CERTIFICATE=$(echo $CERTIFICATE | jq '(.state |= "ACCEPTED")' )
CERT_ID=$(echo $CERTIFICATE | jq -r '.id')

echo "Trusting DDVE ${DDVE_FQDN} certificate $CERTIFICATE"
trust_ppdm_host_certificate "${TOKEN}" "${CERTIFICATE}" "${CERT_ID}"

echo "Adding DDVE ${DDVE_FQDN} to inventory"
DDVE_NAME=$(echo ${DDVE_FQDN} | cut -d '.' -f-1  )
create_ppdm_inventory_source $TOKEN EXTERNALDATADOMAIN ${DDVE_NAME} "${DDVE_FQDN}" $CREDENTIALS_ID
