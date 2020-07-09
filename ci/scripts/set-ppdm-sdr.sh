#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x


echo "installing jq...."
DEBIAN_FRONTEND=noninteractive apt-get install -qq jq < /dev/null > /dev/null
source dps_modules/ci/functions/ppdm_functions.sh
echo "requesting API token"



set_ppdm_sdr-settings "${DDVE_FQDN}" "${DDVE_PATH}" 'DATA_DOMAIN_SYSTEM' 'true'