#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
source dps-modules/ci/functions/ppdm_functions.sh
source dps-modules/ci/functions/yaml.sh


az login --service-principal \
    -u ${AZURE_CLIENT_ID} \
    -p ${AZURE_CLIENT_SECRET} \
    --tenant ${AZURE_TENANT_ID} \
    --output tsv
az account set --subscription ${AZURE_SUBSCRIPTION_ID}  
echo "Starting CDRS Server ane Database"
az mysql server start \
--ids ${CDRS_MYSQL_ID} 
az vm start \
--ids ${CDRS_SERVER_ID}
