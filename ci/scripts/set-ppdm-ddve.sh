#!/bin/bash
set -eu

echo "installing jq...."
DEBIAN_FRONTEND=noninteractive apt-get install -qq jq < /dev/null > /dev/null
source dps_modules/ci/functions/ppdm_functions.sh
echo "requesting API token"


TOKEN=$(get_token ${PPDM_PASSWORD})

echo "Creating DDVE Credentials for ${DDVE_USERNAME}"
CREDENTIALS=$(create_credentials ${TOKEN} DATADOMAIN ${DDVE_USERNAME} ${DDVE_PASSWORD})
CREDENTIALS_ID=$(echo $credentials | jq -r '.id')

CERTIFICATE=$(get_host_certificate $TOKEN $DDVE_FQDN)
CERTIFICATE=$(echo $CERTIFICATE | jq -r '.[]' )
CERTIFICATE=$(echo $CERTIFICATE | jq '(.state |= "ACCEPTED")' )
CERT_ID=$(echo $CERTIFICATE | jq -r '.id')
trust_certificate "${TOKEN}" "${CERTIFICATE}" "${CERT_ID}"

create_inventory_source $TOKEN EXTERNALDATADOMAIN ddve1 ddve1.home.labbuildr.com $CREDENTIALS_ID
