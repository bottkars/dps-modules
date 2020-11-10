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

AKS_CONFIG=$(az aks create -g ${RESOURCE_GROUP} \
  -n ${AKS_CLUSTER_NAME} \
  --network-plugin azure \
  -k 1.17.11 \
  --aks-custom-headers EnableAzureDiskFileCSIDriver=true \
  --subscription ${AZURE_SUBSCRIPTION_ID} \
  --generate-ssh-keys \
  --service-principal ${AKS_APP_ID} \
  --client-secret ${AKS_SECRET} \
  --vnet-subnet-id "/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${RESOURCE_GROUP}-virtual-network/subnets/${RESOURCE_GROUP}-aks-subnet"
)
az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${AKS_CLUSTER_NAME}

kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/master/deploy/example/snapshot/storageclass-azuredisk-snapshot.yaml

timestamp="$(date '+%Y%m%d.%-H%M.%S+%Z')"
export timestamp

KUBECONFIG_OUTPUT_FILE="$(echo "$KUBECONFIG_FILE" | envsubst '$timestamp')"
cp $HOME/.kube/config kubeconfig/"${KUBECONFIG_OUTPUT_FILE}"

AKSCONFIG_OUTPUT_FILE="$(echo "$AKSCONFIG_FILE" | envsubst '$timestamp')"
echo $AKS_CONFIG > aksconfig/"${AKSCONFIG_OUTPUT_FILE}"
