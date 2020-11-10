#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
source dps-modules/ci/functions/ppdm_functions.sh


if [[ -d ppdm-config ]]
then
    PPDM_CONFIG_VERSION=$(cat ./ppdm-config/version) 
    echo "Found PPDM config file, evaluating Variables from configuration Version ${PPDM_CONFIG_VERSION}"
    eval "$(jq -r 'keys[] as $key | "export \($key)=\"\(.[$key].value)\""' ./ppdm-config/tf-output-${PPDM_CONFIG_VERSION}.json)"
fi
echo "Connectring to Azure . . . "
if [[ "$DEVICELOGIN" == "TRUE" ]]
then
    az login --use-device-code --output tsv
else 
    az login --service-principal \
        -u ${AZURE_CLIENT_ID} \
        -p ${AZURE_CLIENT_SECRET} \
        --tenant ${AZURE_TENANT_ID} \
        --output tsv
fi        
az account set --subscription ${AZURE_SUBSCRIPTION_ID}  

az extension add --name aks-preview

az aks delete -g ${RESOURCE_GROUP} \
 -n ${AKS_CLUSTER_NAME} --yes



